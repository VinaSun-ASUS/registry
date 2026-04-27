# Server Allowlist Configuration

## Overview

The MCP Registry supports configuring a server allowlist to restrict which MCP servers are accessible through the API. This is useful for private registry deployments where you want to control which servers can be accessed by clients.

## Configuration

### Environment Variable

Set the `MCP_REGISTRY_ALLOWED_SERVERS` environment variable with a comma-separated list of server names:

```bash
MCP_REGISTRY_ALLOWED_SERVERS="io.figma/mcp-server,io.github.example/another-server"
```

### Behavior

- **When set**: Only servers with names matching the allowlist will be returned by the API
- **When empty or unset**: All servers in the database are accessible (default behavior)
- **Whitespace**: Leading and trailing whitespace around server names is automatically trimmed

## Examples

### Example 1: Allow only Figma MCP Server

If you want to restrict access to only the Figma MCP server:

```bash
MCP_REGISTRY_ALLOWED_SERVERS="io.figma/mcp-server"
```

### Example 2: Allow multiple servers

To allow multiple specific servers:

```bash
MCP_REGISTRY_ALLOWED_SERVERS="io.figma/mcp-server,io.github.domdomegg/airtable-mcp-server,com.example/my-server"
```

### Example 3: Docker Compose Configuration

In your `docker-compose.yml`:

```yaml
services:
  registry:
    image: ghcr.io/modelcontextprotocol/registry:latest
    environment:
      - MCP_REGISTRY_DATABASE_URL=postgres://user:pass@db:5432/mcp-registry
      - MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
    ports:
      - "8080:8080"
```

### Example 4: Using .env file

In your `.env` file:

```bash
MCP_REGISTRY_ALLOWED_SERVERS=io.figma/mcp-server
```

Then reference it in docker-compose.yml:

```yaml
services:
  registry:
    env_file: .env
    # ... other configuration
```

## API Behavior

When the allowlist is configured, the following API endpoints are affected:

- `GET /v0/servers` - Returns only servers in the allowlist
- `GET /v0.1/servers` - Returns only servers in the allowlist
- `GET /v0/servers/{serverName}` - Returns 404 if server is not in allowlist
- `GET /v0.1/servers/{serverName}` - Returns 404 if server is not in allowlist

## Important Notes

1. **Server Name Format**: Server names must match exactly (case-sensitive)
2. **Publishing**: The allowlist only affects read operations. Publishing new servers is controlled by authentication and authorization, not the allowlist
3. **Database Content**: The allowlist does not affect what's stored in the database, only what's returned by the API
4. **Performance**: The allowlist is checked at the database query level for optimal performance

## Finding Server Names

To find the correct server name to use in your allowlist:

1. Search the public registry at https://registry.modelcontextprotocol.io/v0/servers
2. Look for the `name` field in the server's JSON response
3. Use the exact value from the `name` field

Example server name formats:
- `io.figma/mcp-server`
- `io.github.domdomegg/airtable-mcp-server`
- `io.github.example/my-server`

## Troubleshooting

### Server not appearing in results

- Verify the server name matches exactly (check for typos, case sensitivity)
- Ensure there are no extra spaces in the environment variable
- Check that the server exists in your database
- Review the registry logs for any configuration errors

### All servers still showing

- Confirm the environment variable is set correctly
- Restart the registry service after changing the configuration
- Check that the MCP_REGISTRY_ prefix is included in the variable name
