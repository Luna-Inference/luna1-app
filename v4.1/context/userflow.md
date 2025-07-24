# Luna Project - Complete Context Export

## Product Overview
Luna is a hardware AI device that runs a local, private ChatGPT-like assistant. It consists of:
- **Hardware**: Small black rectangular device (like Raspberry Pi in case) with display, power port, and network port
- **Software**: Luna Companion App that runs on user's computer
- **Connection**: Network cable (ethernet-to-USB-C) connects Luna device to user's computer
- **Value Proposition**: Local AI processing, privacy-focused, internet-independent, no usage charges

## Hardware Components
- Luna device (small black rectangular case with display)
- Network cable (ethernet-to-USB-C)
- Power adapter
- Instruction card

## User Journey Flow

### Phase 1: Unboxing & Hardware Setup
1. **Unboxing**: User discovers Luna device, network cable, power adapter, instruction card
2. **Read Instructions**: User follows instruction card to download app
3. **Download App**: Simple page with "LUNA" text and download button
4. **Install & Launch**: User installs and opens Luna Companion App
5. **Welcome Screen**: App shows large "Welcome" text with greeting
6. **Setup Instructions**: App displays "Step 1: Power Device" with illustrations
7. **Power Device**: User plugs power adapter into Luna device
8. **Connection Instructions**: App shows "Step 2: Connect Device" 
9. **Connect Device**: User connects network cable from Luna to computer
10. **Luna Wakes Up**: Luna's display shows cute, friendly face after 30 seconds
11. **App Scanning**: App searches for Luna device with loading animation
12. **Connection Success**: "Luna Device Connected" message with green checkmark
13. **Name Entry**: User enters their name in friendly prompt

### Phase 2: AI Onboarding Chat
14. **Customer Success Chat**: Interactive conversation with Luna AI
15. **Dashboard Transition**: Luna guides user to full dashboard interface

## Luna AI Customer Success Specifications

### Persona
- **Name**: Luna
- **Role**: Customer Success AI Assistant  
- **Personality**: Smart, concise, professional with subtle humor
- **Style**: Conversational, direct, helpful without overwhelming

### Goals
1. Ensure user understands Luna's core functionality
2. Familiarize user with dashboard layout  
3. Address any user questions thoroughly

### Key Features to Explain
- **Chat Interface**: Primary interaction like ChatGPT but local and private
- **Emotional Support**: Available for personal conversations
- **Question Answering**: General knowledge and assistance  
- **Expert Creation (RAG)**: Upload files to create topic-specific experts
- **Automation Tools**: Email, CRM, web search integration (coming soon)
- **Voice Chat**: Real-time voice interaction (incoming feature)

### Value Propositions
- **Privacy**: Runs locally, no data sent to external servers
- **Independence**: Works without internet connection
- **Cost-effective**: No usage charges for core features
- **Reliability**: Always available, no service outages

### Sample Onboarding Conversation
```
Luna: Hi [Name]! I'm Luna, your private AI assistant. I run completely locally on your device - no internet needed, no data sent anywhere, and no usage charges for our core features. Pretty cool, right?

Luna: I can help with chat conversations, emotional support, answering questions, and even become an expert on specific topics when you upload files. We also have automation tools for email and CRM coming soon.

Luna: What would you like to know about first?

[User asks questions...]

Luna: Great questions! You seem ready to explore everything Luna can do. Let me show you your dashboard where you'll find all our AI-powered apps.

Luna: Ready to dive in?
```

## Technical Architecture
- Luna device runs HTTP server locally
- Luna Companion App makes HTTP requests to Luna device
- All processing happens locally on Luna hardware
- No internet connection required for core functionality
- Network cable provides direct device-to-computer communication

## App Requirements

### Setup Flow Screens
1. **Welcome Screen**: Large "Welcome" text with friendly greeting
2. **Setup Instructions**: Step-by-step visual guide for hardware setup
3. **Device Scanning**: Loading screen while searching for Luna device
4. **Connection Success**: Confirmation screen with success indicator
5. **Name Entry**: Simple form to capture user's name
6. **Chat Interface**: Clean chat UI for onboarding conversation
7. **Dashboard**: Grid of AI-powered app tiles and features

### UI/UX Guidelines
- **Visual Style**: Clean, minimal design similar to instruction manual
- **Color Palette**: Limited colors with teal/green accents on white background
- **Illustrations**: Line art style, technical drawing aesthetic
- **Typography**: Clear, readable fonts suitable for instructions
- **Error Handling**: Clear feedback for connection issues with retry options

### Key Features Needed
- Device discovery and connection management
- HTTP communication with Luna device
- Chat interface with message history
- Name persistence for personalization
- Dashboard with app tiles/cards layout
- Error states and retry mechanisms
- Progress indicators for setup steps

## User Success Criteria
By end of onboarding, user should:
- Have Luna device properly connected and functioning
- Understand Luna's core value proposition (local, private, free)
- Know Luna's main capabilities and limitations  
- Feel confident navigating the dashboard interface
- Know how to access Luna for ongoing questions and support

## Development Priorities
1. **Core Setup Flow**: Hardware connection and device discovery
2. **Chat Interface**: Basic messaging with Luna AI
3. **Dashboard Framework**: App tiles and navigation structure
4. **Error Handling**: Connection troubleshooting and retry logic
5. **Polish**: Visual design matching instruction manual aesthetic

## Error Scenarios to Handle
- Luna device not found during scanning
- Connection lost during setup
- Power issues (device not turning on)
- Network cable connection problems
- App launch issues
- Name entry validation

## Future Considerations
- Voice chat integration (upcoming feature)
- Automation tool interfaces (email, CRM, web search)
- File upload for expert creation (RAG system)
- Multi-device support
- Firmware update mechanisms