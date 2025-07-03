from transformers import AutoTokenizer

# Load the Qwen3 tokenizer
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen3-1.7B")

# Your prompt
prompt = "how much wood would a wood chuck chuck if a wood chuck would chuck wood?"

# Tokenize and count tokens
tokens = tokenizer(prompt)
token_count = len(tokens["input_ids"])

print(f"Token count: {token_count}")
