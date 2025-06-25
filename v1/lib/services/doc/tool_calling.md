
tool plan (tool 1, tool 2, tool 3, etc.) + tool 1 + tool 1 param = llm ( user intent + tools available)

tool 1 result = computer (tool 1 + tool 1 param)

tool 2 input = llm (tool 1 result)

tool 2 result = computer (tool 2 + tool 2 input)

tool 3 input = llm (tool 2 result)

... repeat until the end

Luna Agent: Spec v5 (Reactive Workflow)
This document outlines the official, reactive workflow for the Luna Agent. In this model, the agent first creates a high-level plan, then executes it step-by-step, generating the parameters for each command just-in-time based on the latest context.

Core Architecture
The system operates in two distinct phases:

Phase 1: Planning

The LLM receives the user's request and its only job is to create a high-level plan.

LLM Output: A JSON object with a single "plan" key, containing an ordered list of tool names.

Phase 2: Step-by-Step Execution

The system iterates through the generated plan. For each tool in the sequence, it initiates a new "turn" with the LLM.

LLM Input for each turn: The full context, including the original user request, the plan, and all previous tool results.

LLM Output for each turn: A JSON object with a single "params" key, containing the parameters for the tool that is about to be executed.

Test Prompt Structure
This section defines how to test the reactive workflow turn-by-turn.

Turn 1: Generate the Plan
System Prompt to LLM:

Instructions: You are Luna, a helpful AI assistant.

Available Tools: search, send_email

User Request: "Please search for the current price of Bitcoin and email it to my financial advisor at advisor@example.com."

Task: Create a high-level plan to solve the user's request. Respond only with a JSON object containing a "plan" key.

Expected LLM Response:

{
  "plan": [
    "search",
    "send_email"
  ]
}

Turn 2: Generate Parameters for send_email
(This turn occurs after the system has executed the search tool from the plan and has a result).

System Prompt to LLM:

Instructions: You are Luna, a helpful AI assistant.

User Request: "Please search for the current price of Bitcoin and email it to my financial advisor at advisor@example.com."

Plan: ["search", "send_email"]

Previous Step Result (search): "The current price of Bitcoin is $65,432.10 USD."

Current Tool: send_email

Task: Generate the parameters for the send_email tool based on all available information. Respond only with a JSON object containing a "params" key.

Expected LLM Response:

{
  "params": {
    "recipient": "advisor@example.com",
    "subject": "Current Bitcoin Price",
    "body": "Hi, as requested, here is the current price of Bitcoin: $65,432.10 USD."
  }
}

