# SimpleChatBubble Widget

A lightweight, customizable chat bubble widget for Flutter applications. This widget is designed to be used in chat interfaces, providing a clean and modern look with customizable styling options.

## Features

- Support for both user and system messages
- Customizable colors, text styles, and padding
- Optional chat bubble tail/pointer
- Support for leading and trailing widgets (avatars, timestamps, etc.)
- Proper alignment based on message sender
- Smooth border radius styling
- Subtle shadow effect

## Usage

```dart
// Basic usage
SimpleChatBubble(
  text: 'Hello, world!',
  isUserMessage: false,
)

// Customized system message
SimpleChatBubble(
  text: 'System notification',
  maxWidth: 300,
  backgroundColor: Colors.grey.shade100,
  textColor: Colors.black87,
  showTail: false,
)

// User message with custom styling
SimpleChatBubble(
  text: 'This is my message',
  maxWidth: 300,
  backgroundColor: chatBlue,
  textColor: Colors.white,
  isUserMessage: true,
)

// Message with avatar
SimpleChatBubble(
  text: 'Message with avatar',
  isUserMessage: false,
  leading: CircleAvatar(
    radius: 16,
    backgroundImage: AssetImage('assets/avatar.png'),
  ),
)
```

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | String | The message text to display |
| `maxWidth` | double | Maximum width of the chat bubble (default: 300) |
| `backgroundColor` | Color? | Background color of the bubble |
| `textColor` | Color? | Text color |
| `textStyle` | TextStyle? | Custom text style |
| `padding` | EdgeInsets? | Custom padding inside the bubble |
| `isUserMessage` | bool | Whether this is a user message (affects alignment and styling) |
| `showTail` | bool | Whether to show the chat bubble tail/pointer |
| `leading` | Widget? | Widget to display before the bubble (typically for avatars) |
| `trailing` | Widget? | Widget to display after the bubble (typically for timestamps) |

## Example

See `simple_chat_bubble_example.dart` for a complete usage example.