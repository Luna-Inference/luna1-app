// App State Management
let currentScreen = 'welcome-screen';
let userName = '';
let chatConversation = [];
let isScanning = false;

// Screen Navigation
function showScreen(screenId) {
    // Hide all screens
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.remove('active');
    });
    
    // Show target screen
    const targetScreen = document.getElementById(screenId);
    if (targetScreen) {
        targetScreen.classList.add('active');
        currentScreen = screenId;
    }
}

function nextScreen(screenId) {
    showScreen(screenId);
    
    // Special handling for different screens
    if (screenId === 'wait-for-face') {
        startFaceDetection();
    } else if (screenId === 'device-scanning') {
        startDeviceScanning();
    }
}

// Face Detection Logic
function startFaceDetection() {
    const faceTimer = document.getElementById('face-timer');
    const faceCheckButtons = document.getElementById('face-check-buttons');
    const lunaDisplay = document.getElementById('luna-display');
    
    let countdown = 30;
    
    // Update timer every second
    const timerInterval = setInterval(() => {
        countdown--;
        if (countdown > 20) {
            faceTimer.textContent = `Luna is starting up... ${countdown} seconds left. (This is normal!)`;
        } else if (countdown > 10) {
            faceTimer.textContent = `Almost ready... ${countdown} seconds. Watch Luna's little screen!`;
        } else if (countdown > 0) {
            faceTimer.textContent = `Any moment now... ${countdown} seconds. Look for the smiley face!`;
        } else {
            clearInterval(timerInterval);
            // Simulate Luna's face appearing
            showLunaFace();
            faceTimer.textContent = "Luna should be showing a happy face now! Check her little screen.";
            faceCheckButtons.style.display = 'block';
        }
    }, 1000);
}

function showLunaFace() {
    const lunaFaceImage = document.getElementById('luna-face-image');
    lunaFaceImage.src = 'assets/luna-face.png';
    lunaFaceImage.alt = 'Luna device with happy face';
}

function confirmFaceVisible() {
    // User confirms they can see Luna's face
    showScreen('device-scanning');
}

function handleNoFace() {
    // User doesn't see the face - show troubleshooting
    const faceTimer = document.getElementById('face-timer');
    const faceCheckButtons = document.getElementById('face-check-buttons');
    
    faceTimer.innerHTML = `
        <div style="color: #e53e3e; margin-bottom: 1rem;">
            <strong>No problem! Let's figure this out together:</strong>
        </div>
        <ul style="text-align: left; max-width: 500px; margin: 0 auto; line-height: 1.6;">
            <li><strong>Is Luna's power light on?</strong> - Look for a small light anywhere on Luna</li>
            <li><strong>Check the power cable</strong> - Make sure it's pushed all the way into Luna</li>
            <li><strong>Wait a little longer</strong> - Some Luna devices take up to 90 seconds to start</li>
            <li><strong>Try restarting Luna</strong> - Unplug the power for 10 seconds, then plug it back in</li>
            <li><strong>Check different angles</strong> - Sometimes the screen is hard to see from certain positions</li>
        </ul>
        <p style="margin-top: 1rem; font-style: italic;">Remember: You're looking for a smiley face (😊) on Luna's little screen!</p>
    `;
    
    faceCheckButtons.innerHTML = `
        <div class="button-group">
            <button class="primary-btn" onclick="retryFaceDetection()">Try Again</button>
            <button class="secondary-btn" onclick="skipToScanning()">Skip & Continue</button>
        </div>
    `;
}

function retryFaceDetection() {
    // Reset the face detection process
    const faceTimer = document.getElementById('face-timer');
    const faceCheckButtons = document.getElementById('face-check-buttons');
    const lunaFaceImage = document.getElementById('luna-face-image');
    
    // Reset image to initial state
    lunaFaceImage.src = 'assets/luna-intro.png';
    lunaFaceImage.alt = 'Luna device waking up';
    
    faceCheckButtons.style.display = 'none';
    startFaceDetection();
}

function skipToScanning() {
    // Allow user to skip face detection if having issues
    showScreen('device-scanning');
}

// Device Discovery and Connection
async function startDeviceScanning() {
    if (isScanning) return;
    
    isScanning = true;
    const scanOptions = document.querySelector('.scan-options');
    
    // Show scan failed option after 5 seconds
    setTimeout(() => {
        if (currentScreen === 'device-scanning') {
            scanOptions.style.display = 'block';
        }
    }, 5000);
    
    try {
        // Simulate device discovery process
        const deviceFound = await simulateDeviceDiscovery();
        
        if (deviceFound && currentScreen === 'device-scanning') {
            isScanning = false;
            showScreen('connection-success');
        }
    } catch (error) {
        console.error('Device scanning error:', error);
        if (currentScreen === 'device-scanning') {
            isScanning = false;
            showScreen('scan-failed');
        }
    }
}

async function simulateDeviceDiscovery() {
    // Simulate network scanning for Luna device
    return new Promise((resolve) => {
        // Random success/failure for demo purposes
        const scanDuration = Math.random() * 3000 + 2000; // 2-5 seconds
        const success = Math.random() > 0.3; // 70% success rate
        
        setTimeout(() => {
            resolve(success);
        }, scanDuration);
    });
}

// Actual device discovery (for real implementation)
async function discoverLunaDevice() {
    const commonPorts = [3000, 8080, 8000, 3001];
    const localhost = 'http://localhost';
    
    for (const port of commonPorts) {
        try {
            const response = await fetch(`${localhost}:${port}/api/ping`, {
                method: 'GET',
                timeout: 2000
            });
            
            if (response.ok) {
                const data = await response.json();
                if (data.device === 'luna') {
                    return `${localhost}:${port}`;
                }
            }
        } catch (error) {
            // Continue to next port
            continue;
        }
    }
    
    throw new Error('Luna device not found');
}

// Name Entry and Chat Initialization
function startChat() {
    const nameInput = document.getElementById('user-name');
    userName = nameInput.value.trim();
    
    if (!userName) {
        nameInput.focus();
        return;
    }
    
    // Store user name
    localStorage.setItem('lunaUserName', userName);
    
    // Initialize chat
    showScreen('chat-interface');
    initializeChat();
}

function initializeChat() {
    const chatMessages = document.getElementById('chat-messages');
    chatMessages.innerHTML = '';
    
    // Start Luna's onboarding conversation
    const welcomeMessage = `Hi ${userName}! I'm Luna, your private AI assistant. I run completely locally on your device - no internet needed, no data sent anywhere, and no usage charges for our core features. Pretty cool, right?`;
    
    addChatMessage('luna', welcomeMessage);
    
    setTimeout(() => {
        const featuresMessage = "I can help with chat conversations, emotional support, answering questions, and even become an expert on specific topics when you upload files. We also have automation tools for email and CRM coming soon.";
        addChatMessage('luna', featuresMessage);
        
        setTimeout(() => {
            const questionMessage = "What would you like to know about first?";
            addChatMessage('luna', questionMessage);
        }, 2000);
    }, 3000);
}

// Chat Functionality
function addChatMessage(sender, message) {
    const chatMessages = document.getElementById('chat-messages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${sender}`;
    
    if (sender === 'luna') {
        messageDiv.innerHTML = `<div class="message-sender">Luna</div>${message}`;
    } else {
        messageDiv.innerHTML = message;
    }
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    
    // Store in conversation history
    chatConversation.push({ sender, message, timestamp: Date.now() });
}

function sendMessage() {
    const chatInput = document.getElementById('chat-input');
    const message = chatInput.value.trim();
    
    if (!message) return;
    
    // Add user message
    addChatMessage('user', message);
    chatInput.value = '';
    
    // Simulate Luna's response
    setTimeout(() => {
        const response = generateLunaResponse(message);
        addChatMessage('luna', response);
        
        // Check if conversation should end
        if (shouldEndOnboarding()) {
            setTimeout(() => {
                const finalMessage = "Great questions! You seem ready to explore everything Luna can do. Let me show you your dashboard where you'll find all our AI-powered apps.";
                addChatMessage('luna', finalMessage);
                
                setTimeout(() => {
                    const transitionMessage = "Ready to dive in?";
                    addChatMessage('luna', transitionMessage);
                    
                    setTimeout(() => {
                        showScreen('dashboard');
                    }, 2000);
                }, 3000);
            }, 1000);
        }
    }, 1500);
}

function generateLunaResponse(userMessage) {
    const message = userMessage.toLowerCase();
    
    // Simple response logic based on keywords
    if (message.includes('privacy') || message.includes('private') || message.includes('data')) {
        return "Excellent question! Privacy is our core strength. Everything runs locally on your Luna device. Your conversations, files, and data never leave your device or get sent to external servers. You have complete control and privacy.";
    }
    
    if (message.includes('internet') || message.includes('offline') || message.includes('connection')) {
        return "Luna works completely offline! Once set up, you don't need an internet connection for any core features. This means reliable access anytime, faster responses, and no dependency on external services.";
    }
    
    if (message.includes('cost') || message.includes('price') || message.includes('charge') || message.includes('free')) {
        return "No usage charges for core features! Unlike cloud-based AI services that charge per message or token, Luna's local processing means unlimited conversations at no extra cost after your initial device purchase.";
    }
    
    if (message.includes('voice') || message.includes('speak') || message.includes('talk')) {
        return "Voice chat is coming soon! You'll be able to have natural voice conversations with Luna, just like talking to a friend. It'll work completely locally too, so your voice data stays private.";
    }
    
    if (message.includes('file') || message.includes('upload') || message.includes('expert') || message.includes('document')) {
        return "The Expert Creation feature lets you upload documents, PDFs, or text files to create specialized AI assistants. For example, upload your company's handbook to create an HR expert, or research papers to create a topic specialist!";
    }
    
    if (message.includes('automation') || message.includes('email') || message.includes('crm')) {
        return "Automation tools are in development! Soon you'll be able to integrate Luna with your email, CRM systems, and web searches while maintaining privacy. These tools will help streamline your workflow.";
    }
    
    if (message.includes('help') || message.includes('support') || message.includes('emotional')) {
        return "I'm here for both practical help and emotional support. Whether you need assistance with work tasks, want to brainstorm ideas, or just need someone to talk to, I'm designed to be a helpful, understanding companion.";
    }
    
    // Default responses for general questions
    const defaultResponses = [
        "That's a great question! Luna is designed to be your personal AI companion, handling everything from casual conversations to complex problem-solving, all while keeping your data completely private.",
        "I'm glad you're curious! Local processing means faster responses, complete privacy, and reliable access. Plus, you can use Luna as much as you want without worrying about usage costs.",
        "Interesting! Luna combines the power of advanced AI with the security of local processing. Think of me as your personal ChatGPT that lives on your device and never shares your information.",
        "Good point! What makes Luna special is the combination of powerful AI capabilities with complete privacy and independence from internet services. You get the best of both worlds."
    ];
    
    return defaultResponses[Math.floor(Math.random() * defaultResponses.length)];
}

function shouldEndOnboarding() {
    // End onboarding after 3-5 exchanges or if user seems satisfied
    return chatConversation.filter(msg => msg.sender === 'user').length >= 3;
}

function handleChatKeyPress(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
}

// Dashboard Functionality
function initializeDashboard() {
    // Add click handlers to app tiles
    document.querySelectorAll('.app-tile:not(.coming-soon)').forEach(tile => {
        tile.addEventListener('click', () => {
            const appName = tile.querySelector('h3').textContent;
            handleAppTileClick(appName);
        });
    });
}

function handleAppTileClick(appName) {
    // For demo purposes, just show an alert
    // In a real app, this would navigate to the specific app
    alert(`Opening ${appName} app... (This would navigate to the ${appName} interface in a real implementation)`);
}

// Utility Functions
function saveAppState() {
    const state = {
        currentScreen,
        userName,
        chatConversation,
        timestamp: Date.now()
    };
    localStorage.setItem('lunaAppState', JSON.stringify(state));
}

function loadAppState() {
    const savedState = localStorage.getItem('lunaAppState');
    if (savedState) {
        try {
            const state = JSON.parse(savedState);
            // Only restore state if it's recent (within 24 hours)
            if (Date.now() - state.timestamp < 24 * 60 * 60 * 1000) {
                currentScreen = state.currentScreen;
                userName = state.userName;
                chatConversation = state.chatConversation;
                return true;
            }
        } catch (error) {
            console.error('Error loading app state:', error);
        }
    }
    return false;
}

// Initialize App
document.addEventListener('DOMContentLoaded', function() {
    // Load saved user name if exists
    const savedName = localStorage.getItem('lunaUserName');
    if (savedName) {
        userName = savedName;
        const nameInput = document.getElementById('user-name');
        if (nameInput) {
            nameInput.value = savedName;
        }
    }
    
    // Initialize dashboard functionality
    initializeDashboard();
    
    // Show welcome screen by default
    showScreen('welcome-screen');
});

// Save state before page unload
window.addEventListener('beforeunload', saveAppState);

// Export functions for potential external use
window.LunaApp = {
    showScreen,
    nextScreen,
    startChat,
    sendMessage,
    discoverLunaDevice
};