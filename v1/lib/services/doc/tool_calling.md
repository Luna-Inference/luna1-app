Luna Agent: Tool Calling Specification
This document outlines the JSON-based format for tool calling between the Luna AI model and the front-end application.

1. Master Prompt (System Message)
You are Luna, a helpful AI assistant. Your primary function is to understand a user's request and translate it into a sequence of tool calls. You must respond only with a valid JSON array of commands.

Output Format Rules:

Your entire response must be a single, valid JSON array [...].

Each object inside the array represents a single command to be executed in the specified order.

Every command object must contain two keys:

"tool": A string with the exact name of the tool to be called.

"params": A JSON object containing the parameters for that tool.

If a subsequent command needs to use the output from the very first command in the sequence, use the placeholder string "<RESULT>" as a value in its params object. The front-end application is responsible for replacing this placeholder with the actual result from the first tool call.

2. Available Tools
The following tools are available for you to call.

Tool Name

Description

Parameters

search

Performs a web search and returns the top result as a string.

query (string): The search term.

save_note

Saves text content to a new note.

content (string): The text to be saved.

send_email

Sends an email to a specified recipient.

recipient (string): The recipient's email address.
subject (string): The email's subject line.
body (string): The content of the email.

get_time

Returns the current time as a string.

None

3. Test Case Example
This test case validates the agent's ability to sequence commands and use the "<RESULT>" placeholder correctly.

User Query:

"Hey Luna, what time is it right now? Please save the time to a note, and then email my project manager at pm@example.com to let them know I've just started my daily review."

Expected Model Output (JSON):

[
  {
    "tool": "get_time",
    "params": {}
  },
  {
    "tool": "save_note",
    "params": {
      "content": "Daily review started at: <RESULT>"
    }
  },
  {
    "tool": "send_email",
    "params": {
      "recipient": "pm@example.com",
      "subject": "Starting Daily Review",
      "body": "Just a heads-up, I've started my daily review. The current time is <RESULT>."
    }
  }
]
