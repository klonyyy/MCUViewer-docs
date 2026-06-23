
(MCPServer)=
# AI Agent Integration

MCUViewer includes a built-in [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server. This allows AI coding assistants such as GitHub Copilot and Claude Code to connect to a running MCUViewer instance directly from your editor. The agent can then analyze the traces, automatically start and stop acquisition, create whole project and much more. 

The MCP server is exposed over HTTP at `http://localhost:<port>/mcp`. The port can be changed in the {ref}`AcquisitionSettings` window.

```{note}
If the configured port is already taken by another application, MCUViewer will automatically increment it until a free port is found. Make sure the port used in your AI assistant configuration file matches the one shown in the Acquisition Settings window.
```

## GitHub Copilot setup

Create a `.vscode/mcp.json` file in your project with the following content:

```json
{
  "servers": {
    "mcuviewer": {
      "url": "http://localhost:8765/mcp"
    }
  }
}
```

## Claude Code setup

Create a `.mcp.json` file in your project root with the following content:

```json
{
  "servers": {
    "mcuviewer": {
      "url": "http://localhost:8765/mcp"
    }
  }
}
```

```{note}
Sometimes it might be needed to enter your agent's settings and restart the MCP server or open a new chat. 
```

Once the configuration file is in place and MCUViewer is running, your AI assistant will be able to connect to MCUViewer through the MCP server. It is possible to create multiple mcuviewer server json entries for multiple mcuviewer instances. 
