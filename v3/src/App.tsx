import React, { useState, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import { Send, Paperclip } from 'lucide-react';
import './App.css';

interface Message {
  id: string;
  content: string;
  sender: 'user' | 'ai';
  timestamp: Date;
  thinkContent?: string;
}

function App() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [attachedFiles, setAttachedFiles] = useState<File[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [isLoading, setIsLoading] = useState(false);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  React.useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async () => {
    if ((!inputValue.trim() && attachedFiles.length === 0) || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      content: inputValue,
      sender: 'user',
      timestamp: new Date()
    };

    const newMessages = [...messages, userMessage];
    setMessages(newMessages);
    setInputValue('');
    setAttachedFiles([]);
    setIsLoading(true);

    const aiMessageId = (Date.now() + 1).toString();
    // Add placeholder
    setMessages(prev => [...prev, {
      id: aiMessageId,
      content: '...',
      sender: 'ai',
      timestamp: new Date()
    }]);

    try {
      const apiMessages = newMessages.map(msg => ({
        role: msg.sender === 'ai' ? 'assistant' : 'user',
        content: msg.content
      }));

      const response = await fetch('http://100.76.203.80:8080/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'luna-small',
          messages: apiMessages,
          stream: true,
        }),
      });

      if (!response.ok || !response.body) {
        const errorText = response ? await response.text() : 'No response';
        throw new Error(`API error: ${response.status} - ${errorText}`);
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      let fullResponse = '';
      let thinkContent = '';
      let inThinkBlock = false;

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || ''; // Keep incomplete line in buffer

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.substring(6).trim();
            if (data === '[DONE]') {
              break;
            }
            try {
              const json = JSON.parse(data);
              let deltaContent = json.choices?.[0]?.delta?.content || '';

              if (deltaContent) {
                while (deltaContent.length > 0) {
                  if (inThinkBlock) {
                    const endTagIndex = deltaContent.indexOf('</think>');
                    if (endTagIndex !== -1) {
                      thinkContent += deltaContent.substring(0, endTagIndex);
                      deltaContent = deltaContent.substring(endTagIndex + '</think>'.length);
                      inThinkBlock = false;
                    } else {
                      thinkContent += deltaContent;
                      deltaContent = '';
                    }
                  } else {
                    const startTagIndex = deltaContent.indexOf('<think>');
                    if (startTagIndex !== -1) {
                      fullResponse += deltaContent.substring(0, startTagIndex);
                      deltaContent = deltaContent.substring(startTagIndex + '<think>'.length);
                      inThinkBlock = true;
                    } else {
                      fullResponse += deltaContent;
                      deltaContent = '';
                    }
                  }
                }
                
                setMessages(prev => prev.map(msg => 
                  msg.id === aiMessageId ? { ...msg, content: fullResponse, thinkContent: thinkContent } : msg
                ));
              }
            } catch (e) {
              console.error('Error parsing stream data:', e, 'Data:', data);
            }
          }
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred.';
      setMessages(prev => prev.map(msg => 
        msg.id === aiMessageId ? { ...msg, content: `Error: ${errorMessage}` } : msg
      ));
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleFileAttach = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    setAttachedFiles(prev => [...prev, ...files]);
  };

  const removeFile = (index: number) => {
    setAttachedFiles(prev => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="App">
      {messages.length === 0 ? (
        // Empty state - centered logo and input
        <div className="empty-state">
          <div className="logo-container">
            <div className="logo">AI</div>
            <h1>What can I help you with?</h1>
          </div>
          
          <div className="centered-input-container">
            {attachedFiles.length > 0 && (
              <div className="attached-files">
                {attachedFiles.map((file, index) => (
                  <div key={index} className="attached-file">
                    <span>{file.name}</span>
                    <button onClick={() => removeFile(index)}>×</button>
                  </div>
                ))}
              </div>
            )}
            
            <div className="input-row">
              <button 
                className="attach-button"
                onClick={handleFileAttach}
                title="Attach files"
              >
                <Paperclip size={18} />
              </button>
              
              <textarea
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Ask me anything..."
                className="message-input centered-input"
                rows={1}
                disabled={isLoading}
              />
              
              <button 
                className="send-button"
                onClick={handleSend}
                disabled={(!inputValue.trim() && attachedFiles.length === 0) || isLoading}
              >
                <Send size={18} />
              </button>
            </div>
          </div>
        </div>
      ) : (
        // Chat view - messages and bottom input
        <div className="chat-container">
          <div className="messages-container">
            {messages.map((message) => (
              <div key={message.id} className={`message ${message.sender}`}>
                <div className="message-content">
                  {message.sender === 'ai' ? (
                    <>
                      {message.thinkContent && (
                        <details className="think-block">
                          <summary>Show thought process</summary>
                          <ReactMarkdown>{message.thinkContent}</ReactMarkdown>
                        </details>
                      )}
                      <ReactMarkdown>{message.content}</ReactMarkdown>
                    </>
                  ) : (
                    <p>{message.content}</p>
                  )}
                </div>
                <div className="message-timestamp">
                  {message.timestamp.toLocaleTimeString()}
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          <div className="input-container">
            {attachedFiles.length > 0 && (
              <div className="attached-files">
                {attachedFiles.map((file, index) => (
                  <div key={index} className="attached-file">
                    <span>{file.name}</span>
                    <button onClick={() => removeFile(index)}>×</button>
                  </div>
                ))}
              </div>
            )}
            
            <div className="input-row">
              <button 
                className="attach-button"
                onClick={handleFileAttach}
                title="Attach files"
              >
                <Paperclip size={18} />
              </button>
              
              <textarea
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Ask a follow up..."
                className="message-input"
                rows={1}
                disabled={isLoading}
              />
              
              <button 
                className="send-button"
                onClick={handleSend}
                disabled={(!inputValue.trim() && attachedFiles.length === 0) || isLoading}
              >
                <Send size={18} />
              </button>
            </div>
          </div>
        </div>
      )}

      <input
        ref={fileInputRef}
        type="file"
        multiple
        onChange={handleFileChange}
        style={{ display: 'none' }}
      />
    </div>
  );
}

export default App;
