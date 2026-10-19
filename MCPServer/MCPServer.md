---
description: "Connect AI coding assistants such as GitHub Copilot and Claude Code to MCUViewer through its built-in MCP server to analyze traces and control acquisition."
---
(MCPServer)=
# AI Agent Integration

MCUViewer includes a built-in [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server. This allows AI coding assistants such as GitHub Copilot and Claude Code to connect to a running MCUViewer instance directly from your editor. The agent can then analyze the traces, automatically start and stop acquisition, create whole project and much more. 

The MCP server is exposed over HTTP at `http://localhost:<port>/mcp`. The default port is `8765` and it can be changed with the `MCP server port` field in the `Advanced` section of the {ref}`AcquisitionSettings` window. The port is saved in the project file.

The `MCP server` indicator in the bottom right corner of the status bar shows whether an agent is connected - hover over it to see the port the server actually runs on.

```{note}
If the configured port is already taken by another application (for example another MCUViewer instance), MCUViewer will automatically increment it until a free port is found. Make sure the port used in your AI assistant configuration file matches the one shown by the status bar indicator.
```

## GitHub Copilot setup

Create a `.vscode/mcp.json` file in your project with the following content:

```json
{
  "servers": {
    "mcuviewer": {
      "type": "http",
      "url": "http://localhost:8765/mcp"
    }
  }
}
```

## Claude Code setup

Create a `.mcp.json` file in your project root with the following content:

```json
{
  "mcpServers": {
    "mcuviewer": {
      "type": "http",
      "url": "http://localhost:8765/mcp"
    }
  }
}
```

or add the server from the terminal:

```
claude mcp add --transport http mcuviewer http://localhost:8765/mcp
```

```{note}
Sometimes it might be needed to enter your agent's settings and restart the MCP server or open a new chat. 
```

Once the configuration file is in place and MCUViewer is running, your AI assistant will be able to connect to MCUViewer through the MCP server. It is possible to create multiple mcuviewer server json entries for multiple mcuviewer instances. 
