const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const port = process.env.MCP_SERVER_PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({ 
      status: 'unhealthy', 
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message 
    });
  }
});

// MCP Protocol endpoint
app.post('/mcp', async (req, res) => {
  try {
    const { type, name, arguments: args } = req.body;

    if (type !== 'function') {
      return res.status(400).json({
        error: 'Invalid request type. Expected "function"',
        received: type
      });
    }

    switch (name) {
      case 'resources':
        return await handleResourcesRequest(req, res);
      
      case 'query':
        return await handleQueryRequest(req, res, args);
      
      case 'schema':
        return await handleSchemaRequest(req, res, args);
        
      default:
        return res.status(400).json({
          error: 'Unknown function name',
          supported: ['resources', 'query', 'schema']
        });
    }
  } catch (error) {
    console.error('MCP request failed:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Handle resources request - lists available database resources
async function handleResourcesRequest(req, res) {
  try {
    const client = await pool.connect();
    
    // Get tables from all schemas
    const tablesQuery = `
      SELECT 
        schemaname as schema,
        tablename as name,
        'table' as type
      FROM pg_tables 
      WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
      UNION ALL
      SELECT 
        schemaname as schema,
        viewname as name,
        'view' as type
      FROM pg_views 
      WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
      ORDER BY schema, name;
    `;
    
    const result = await client.query(tablesQuery);
    client.release();
    
    const resources = result.rows.map(row => ({
      uri: `postgresql://${row.schema}.${row.name}`,
      name: `${row.schema}.${row.name}`,
      description: `${row.type} in ${row.schema} schema`,
      mimeType: 'application/json'
    }));

    res.json({
      resources,
      _meta: {
        total: resources.length,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Resources request failed:', error);
    res.status(500).json({
      error: 'Failed to retrieve resources',
      message: error.message
    });
  }
}

// Handle query request - executes SQL queries (read-only)
async function handleQueryRequest(req, res, args) {
  if (!args || !args.query) {
    return res.status(400).json({
      error: 'Missing query parameter',
      required: 'arguments.query'
    });
  }

  const query = args.query.trim();
  
  // Basic protection: only allow SELECT statements
  if (!query.toLowerCase().startsWith('select')) {
    return res.status(403).json({
      error: 'Only SELECT queries are allowed',
      query: query.substring(0, 100) + (query.length > 100 ? '...' : '')
    });
  }

  try {
    const client = await pool.connect();
    const startTime = Date.now();
    
    const result = await client.query(query);
    
    const executionTime = Date.now() - startTime;
    client.release();

    res.json({
      data: result.rows,
      meta: {
        rowCount: result.rowCount,
        fields: result.fields.map(f => ({
          name: f.name,
          dataTypeID: f.dataTypeID,
          dataTypeSize: f.dataTypeSize
        })),
        executionTimeMs: executionTime,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Query execution failed:', error);
    res.status(400).json({
      error: 'Query execution failed',
      message: error.message,
      query: query.substring(0, 200) + (query.length > 200 ? '...' : '')
    });
  }
}

// Handle schema request - gets schema information
async function handleSchemaRequest(req, res, args) {
  const schemaName = args?.schema || 'public';
  
  try {
    const client = await pool.connect();
    
    const schemaQuery = `
      SELECT 
        c.table_name,
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default,
        c.ordinal_position
      FROM information_schema.columns c
      JOIN information_schema.tables t ON c.table_name = t.table_name
      WHERE c.table_schema = $1
      AND t.table_schema = $1
      ORDER BY c.table_name, c.ordinal_position;
    `;
    
    const result = await client.query(schemaQuery, [schemaName]);
    client.release();
    
    // Group columns by table
    const tables = {};
    result.rows.forEach(row => {
      if (!tables[row.table_name]) {
        tables[row.table_name] = {
          name: row.table_name,
          schema: schemaName,
          columns: []
        };
      }
      
      tables[row.table_name].columns.push({
        name: row.column_name,
        type: row.data_type,
        nullable: row.is_nullable === 'YES',
        default: row.column_default,
        position: row.ordinal_position
      });
    });

    res.json({
      schema: schemaName,
      tables: Object.values(tables),
      _meta: {
        tableCount: Object.keys(tables).length,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Schema request failed:', error);
    res.status(500).json({
      error: 'Failed to retrieve schema',
      message: error.message
    });
  }
}

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// Start server
async function startServer() {
  try {
    // Test database connection
    await pool.query('SELECT 1');
    console.log('✅ Database connection established');
    
    app.listen(port, '0.0.0.0', () => {
      console.log(`🚀 MCP Server running on port ${port}`);
      console.log(`📊 Health check: http://localhost:${port}/health`);
      console.log(`🔗 MCP endpoint: http://localhost:${port}/mcp`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down server...');
  await pool.end();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down server...');
  await pool.end();
  process.exit(0);
});

startServer();
