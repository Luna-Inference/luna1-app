// App State Management
let currentScreen = 'welcome-screen';
let userName = '';
let chatConversation = [];
let isScanning = false;

// Screen Navigation
function showScreen(screenId) {
    console.log(`Attempting to show screen: ${screenId}`);
    // Hide all screens
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.remove('active');
    });
    
    // Show target screen
    const targetScreen = document.getElementById(screenId);
    if (targetScreen) {
        targetScreen.classList.add('active');
        currentScreen = screenId;
        console.log(`Successfully switched to screen: ${currentScreen}`);
        
        // Trigger screen-specific animations
        if (screenId === 'welcome-screen') {
            animateWelcomeScreen();
        } else if (screenId === 'hardware-check') {
            animateHardwareCheckScreen();
        } else if (screenId === 'setup-step1') {
            animateSetupStep1();
        } else if (screenId === 'setup-step2') {
            animateSetupStep2();
        } else if (screenId === 'startup-wait-screen') {
            animateStartupWaitScreen();
        }
    } else {
        console.error(`Screen with ID "${screenId}" not found.`);
    }
}

function nextScreen(screenId) {
    console.log(`Navigating to next screen: ${screenId}`);
    showScreen(screenId);
    
    // Special handling for different screens
    if (screenId === 'startup-wait-screen') {
        setTimeout(() => {
            nextScreen('face-selection-screen');
        }, 30000); // 30-second wait
    } else if (screenId === 'device-scanning') {
        startDeviceScanning();
    }
}

// Hardware Check Logic
function handleHardwareResponse(response) {
    if (response === 'yes') {
        // Skip straight to scanning phase
        nextScreen('device-scanning');
    } else {
        // Go through normal setup flow
        nextScreen('setup-step1');
    }
}

// Face Selection Logic
function handleFaceSelection(selection) {
    if (selection === 'correct') {
        nextScreen('device-scanning');
    } else {
        nextScreen('face-troubleshooting-screen');
    }
}

// Startup Wait Screen Animation
function animateStartupWaitScreen() {
    const elements = [
        { selector: '#startup-wait-screen .step-header', delay: 0 },
        { selector: '#startup-wait-screen .loading-animation', delay: 600 },
        { selector: '#startup-wait-screen .detailed-instructions', delay: 1200 }
    ];
    
    // Animate initial elements
    elements.forEach(({ selector, delay }) => {
        setTimeout(() => {
            const element = document.querySelector(selector);
            if (element) {
                element.classList.add('show');
            }
        }, delay);
    });
    
    // Animate organic features with longer intervals for reading
    const organicFeatures = document.querySelectorAll('#startup-organic-showcase .organic-feature');
    const featureInterval = 4000; // 4 seconds between each feature
    const startDelay = 2000; // Start after initial elements
    
    organicFeatures.forEach((feature, index) => {
        setTimeout(() => {
            feature.classList.add('show');
        }, startDelay + (index * featureInterval));
    });
}

// Device Discovery and Connection
async function startDeviceScanning() {
    console.log('startDeviceScanning function called.');
    if (isScanning) {
        console.log('Device scanning is already in progress. Aborting.');
        return;
    }

    isScanning = true;
    console.log('isScanning set to true.');

    // Automatically move to the next screen after 5 seconds
    setTimeout(() => {
        console.log(`setTimeout callback executed. Current screen is: ${currentScreen}`);
        if (currentScreen === 'device-scanning') {
            console.log('Condition met. Moving to connection-success screen.');
            isScanning = false;
            showScreen('connection-success');
        } else {
            console.log(`Condition not met. Not moving to connection-success screen. Current screen: ${currentScreen}`);
        }
    }, 5000);
}

async function simulateDeviceDiscovery() {
    // Simulate network scanning for Luna device
    return new Promise((resolve) => {
        // Always succeed for demo purposes
        const scanDuration = Math.random() * 2000 + 1000; // 1-3 seconds
        const success = true; // Always succeed
        
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
            showRecommendations();
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
    }, 1500);
}

function showRecommendations() {
    const recommendationsContainer = document.getElementById('chat-recommendations');
    recommendationsContainer.innerHTML = '';

    const recommendations = [
        'What can you do?',
        'How does local AI work?',
        'Tell me about Luna privacy features',
        'Start using the application'
    ];

    recommendations.forEach(rec => {
        const button = document.createElement('button');
        button.className = 'recommendation-btn';
        button.textContent = rec;
        button.onclick = () => handleRecommendationClick(rec);
        recommendationsContainer.appendChild(button);
    });
}

function handleRecommendationClick(recommendation) {
    // Remove the clicked button
    const recommendationsContainer = document.getElementById('chat-recommendations');
    const buttons = recommendationsContainer.querySelectorAll('.recommendation-btn');
    buttons.forEach(button => {
        if (button.textContent === recommendation) {
            button.style.display = 'none';
        }
    });

    if (recommendation === 'Start using the application') {
        addChatMessage('user', recommendation);
        setTimeout(() => {
            const response = "Let's get you started using the application.";
            addChatMessage('luna', response);
            setTimeout(() => {
                showDashboardWithChat();
            }, 1500);
        }, 1000);
    } else {
        addChatMessage('user', recommendation);
        setTimeout(() => {
            const response = generateLunaResponse(recommendation);
            addChatMessage('luna', response);
        }, 1500);
    }
}

function showDashboardWithChat() {
    const appContainer = document.querySelector('.app-container');
    const chatInterface = document.getElementById('chat-interface');
    const dashboard = document.getElementById('dashboard');
    const chatToggleBtn = document.getElementById('chat-toggle-btn');

    appContainer.classList.add('dashboard-view');
    chatInterface.classList.add('minimized', 'show');
    dashboard.classList.add('active-alongside-chat');
    chatToggleBtn.classList.remove('hidden');

    // Ensure other screens are not active
    document.querySelectorAll('.screen').forEach(screen => {
        if (screen.id !== 'chat-interface' && screen.id !== 'dashboard') {
            screen.classList.remove('active');
        }
    });

    showScreen('dashboard');
    chatInterface.classList.add('active');
}

function toggleChat() {
    const chatInterface = document.getElementById('chat-interface');
    chatInterface.classList.toggle('show');
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

// Welcome Screen Animation
function animateWelcomeScreen() {
    const elements = [
        { selector: '.welcome-content h1', delay: 0 },
        { selector: '.welcome-content .welcome-subtitle', delay: 600 },
        { selector: '.welcome-content .welcome-device', delay: 1200 }
        // Button will be shown after typing completes
    ];
    
    elements.forEach(({ selector, delay }) => {
        setTimeout(() => {
            const element = document.querySelector(selector);
            if (element) {
                element.classList.add('show');
            }
        }, delay);
    });
    
    // Show and animate chat bubble after device appears
    setTimeout(() => {
        const chatBubble = document.querySelector('.welcome-chat-bubble');
        if (chatBubble) {
            chatBubble.classList.add('show');
            // Start typing animation
            setTimeout(() => {
                startTypingAnimation();
            }, 500);
        }
    }, 1800);
}

// Typing Animation Function
function startTypingAnimation() {
    const typingElement = document.querySelector('.welcome-chat-bubble .typing-text');
    if (!typingElement) return;
    
    const fullText = typingElement.textContent;
    typingElement.textContent = '';
    typingElement.classList.add('typing');
    
    let currentIndex = 0;
    const typingSpeed = 50; // milliseconds per character
    
    function typeNextCharacter() {
        if (currentIndex < fullText.length) {
            typingElement.textContent += fullText[currentIndex];
            currentIndex++;
            setTimeout(typeNextCharacter, typingSpeed);
        } else {
            // Typing complete - remove cursor
            setTimeout(() => {
                typingElement.classList.remove('typing');
                typingElement.classList.add('typing-complete');
                
                // Show button 1 second after typing completes
                setTimeout(() => {
                    const button = document.querySelector('.welcome-content .get-started-btn');
                    if (button) {
                        button.classList.add('show');
                    }
                }, 1000);
            }, 1000);
        }
    }
    
    typeNextCharacter();
}

// Hardware Check Screen Animation
function animateHardwareCheckScreen() {
    const elements = [
        { selector: '#hardware-check .step-header', delay: 0 },
        { selector: '#hardware-check .luna-avatar', delay: 600 },
        { selector: '#hardware-check .chat-bubble', delay: 1200 }
    ];
    
    elements.forEach(({ selector, delay }) => {
        setTimeout(() => {
            const element = document.querySelector(selector);
            if (element) {
                element.classList.add('show');
            }
        }, delay);
    });
    
    // Start typing animation after chat bubble appears
    setTimeout(() => {
        const typingElement = document.querySelector('#hardware-check .chat-bubble .typing-text');
        if (typingElement) {
            startHardwareCheckTypingAnimation(typingElement);
        }
    }, 1800);
}

// Hardware Check Typing Animation
function startHardwareCheckTypingAnimation(element) {
    if (!element) return;
    
    const fullText = element.textContent;
    element.textContent = '';
    element.classList.add('typing');
    
    let currentIndex = 0;
    const typingSpeed = 40;
    
    function typeNextCharacter() {
        if (currentIndex < fullText.length) {
            element.textContent += fullText[currentIndex];
            currentIndex++;
            setTimeout(typeNextCharacter, typingSpeed);
        } else {
            setTimeout(() => {
                element.classList.remove('typing');
                element.classList.add('typing-complete');
                
                // Show response buttons after typing completes
                setTimeout(() => {
                    const buttons = document.querySelector('#hardware-check .hardware-response-buttons');
                    if (buttons) {
                        buttons.classList.add('show');
                    }
                }, 500);
            }, 500);
        }
    }
    
    typeNextCharacter();
}

// Setup Step 1 Animation
function animateSetupStep1() {
    const elements = [
        { selector: '#setup-step1 .step-header', delay: 0 },
        { selector: '#setup-step1 .setup-step-block:nth-child(1)', delay: 600 },
        { selector: '#setup-step1 .setup-step-block:nth-child(2)', delay: 1200 },
        { selector: '#setup-step1 .setup-step-block:nth-child(3)', delay: 1800 }
    ];
    
    elements.forEach(({ selector, delay }) => {
        setTimeout(() => {
            const element = document.querySelector(selector);
            if (element) {
                element.classList.add('show');
            }
        }, delay);
    });
    
    // Animate component chat bubble after first block
    setTimeout(() => {
        const componentBubble = document.querySelector('#setup-step1 .component-chat-bubble');
        if (componentBubble) {
            componentBubble.classList.add('show');
            setTimeout(() => {
                const typingText = componentBubble.querySelector('.component-typing-text');
                if (typingText) {
                    startComponentTypingAnimation(typingText);
                }
            }, 300);
        }
    }, 1000);
    
    // Animate first step chat bubble after component bubble finishes
    setTimeout(() => {
        const firstStepBubble = document.querySelector('#setup-step1 .step-chat-bubble:first-of-type');
        if (firstStepBubble) {
            firstStepBubble.classList.add('show');
            setTimeout(() => {
                const typingText = firstStepBubble.querySelector('.step-typing-text');
                if (typingText) {
                    startStepTypingAnimation(typingText);
                }
            }, 500);
        }
    }, 4000); // Wait longer for component bubble to finish
    
    // Animate second step chat bubble after first one finishes
    setTimeout(() => {
        const stepBubbles = document.querySelectorAll('#setup-step1 .step-chat-bubble');
        const secondStepBubble = stepBubbles[1]; // Get the second bubble explicitly
        if (secondStepBubble) {
            secondStepBubble.classList.add('show');
            setTimeout(() => {
                const typingText = secondStepBubble.querySelector('.step-typing-text');
                if (typingText) {
                    startStepTypingAnimation(typingText);
                }
            }, 500);
        }
    }, 6000); // Wait for first step bubble to finish
}

// Setup Step 2 Animation
function animateSetupStep2() {
    const elements = [
        { selector: '#setup-step2 .step-header', delay: 0 },
        { selector: '#setup-step2 .setup-step-block:nth-child(1)', delay: 600 },
        { selector: '#setup-step2 .setup-step-block:nth-child(2)', delay: 1200 },
        { selector: '#setup-step2 .setup-step-block:nth-child(3)', delay: 1800 }
    ];
    
    elements.forEach(({ selector, delay }) => {
        setTimeout(() => {
            const element = document.querySelector(selector);
            if (element) {
                element.classList.add('show');
            }
        }, delay);
    });
    
    // Animate component chat bubble after first block
    setTimeout(() => {
        const componentBubble = document.querySelector('#setup-step2 .component-chat-bubble');
        if (componentBubble) {
            componentBubble.classList.add('show');
            setTimeout(() => {
                const typingText = componentBubble.querySelector('.component-typing-text');
                if (typingText) {
                    startComponentTypingAnimation(typingText);
                }
            }, 300);
        }
    }, 1000);
    
    // Animate first step chat bubble after component bubble finishes
    setTimeout(() => {
        const firstStepBubble = document.querySelector('#setup-step2 .step-chat-bubble:first-of-type');
        if (firstStepBubble) {
            firstStepBubble.classList.add('show');
            setTimeout(() => {
                const typingText = firstStepBubble.querySelector('.step-typing-text');
                if (typingText) {
                    startStepTypingAnimation(typingText);
                }
            }, 500);
        }
    }, 4000); // Wait longer for component bubble to finish
    
    // Animate second step chat bubble after first one finishes
    setTimeout(() => {
        const stepBubbles = document.querySelectorAll('#setup-step2 .step-chat-bubble');
        const secondStepBubble = stepBubbles[1]; // Get the second bubble explicitly
        if (secondStepBubble) {
            secondStepBubble.classList.add('show');
            setTimeout(() => {
                const typingText = secondStepBubble.querySelector('.step-typing-text');
                if (typingText) {
                    startStepTypingAnimation(typingText);
                }
            }, 500);
        }
    }, 6000); // Wait for first step bubble to finish
}

// Setup Typing Animation Function
function startSetupTypingAnimation(selector) {
    const typingElement = document.querySelector(selector);
    if (!typingElement) return;
    
    const fullText = typingElement.textContent;
    typingElement.textContent = '';
    typingElement.classList.add('typing');
    
    let currentIndex = 0;
    const typingSpeed = 40; // milliseconds per character
    
    function typeNextCharacter() {
        if (currentIndex < fullText.length) {
            typingElement.textContent += fullText[currentIndex];
            currentIndex++;
            setTimeout(typeNextCharacter, typingSpeed);
        } else {
            // Typing complete - remove cursor
            setTimeout(() => {
                typingElement.classList.remove('typing');
                typingElement.classList.add('typing-complete');
            }, 1000);
        }
    }
    
    typeNextCharacter();
}

// Component Typing Animation Function
function startComponentTypingAnimation(element) {
    if (!element) return;
    
    const fullText = element.textContent;
    element.textContent = '';
    element.classList.add('typing');
    
    let currentIndex = 0;
    const typingSpeed = 35;
    
    function typeNextCharacter() {
        if (currentIndex < fullText.length) {
            element.textContent += fullText[currentIndex];
            currentIndex++;
            setTimeout(typeNextCharacter, typingSpeed);
        } else {
            setTimeout(() => {
                element.classList.remove('typing');
                element.classList.add('typing-complete');
            }, 500);
        }
    }
    
    typeNextCharacter();
}

// Step Typing Animation Function
function startStepTypingAnimation(element) {
    if (!element) return;
    
    const fullText = element.textContent;
    element.textContent = '';
    element.classList.add('typing');
    
    let currentIndex = 0;
    const typingSpeed = 50;
    
    function typeNextCharacter() {
        if (currentIndex < fullText.length) {
            element.textContent += fullText[currentIndex];
            currentIndex++;
            setTimeout(typeNextCharacter, typingSpeed);
        } else {
            setTimeout(() => {
                element.classList.remove('typing');
                element.classList.add('typing-complete');
            }, 1000);
        }
    }
    
    typeNextCharacter();
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