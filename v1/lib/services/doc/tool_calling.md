# Tool Call Test Prompt

## Available Tools

You have access to the following tools:

**search(query)**
- Performs a web search and returns the top result
- Parameters: `query` (String) - The search term
- Returns: String content from search results

**sendEmail(recipient, subject, body)**  
- Sends an email to a specified recipient
- Parameters: 
  - `recipient` (String) - Email address to send to
  - `subject` (String) - Email subject line (optional, defaults to "Message from Luna")
  - `body` (String) - Email content
- Returns: None (confirms email sent)

**getTodayDate()**
- Returns today's date in YYYY-MM-DD format
- Parameters: None
- Returns: String date in YYYY-MM-DD format

## Output Format

When you need to use a tool, you MUST format your response exactly as follows:

```
[Brief explanation of what you're doing]

{"name": "toolName", "parameters": {"param1": "value1", "param2": "value2"}}
```
