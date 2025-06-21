import React, { useState, useEffect } from 'react';
import Message from './Message';
import ChatInput from './ChatInput';
import './ChatPage.css';

const ChatPage = () => {
  const [messages, setMessages] = useState([]);

  const handleSendMessage = async (text) => {
    const userMessage = { text, sender: 'user' };
    setMessages((prevMessages) => [...prevMessages, userMessage]);

    try {
      const response = await fetch('http://100.76.203.80:8080/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4',
          messages: [{ role: 'user', content: text }],
          stream: true,
        }),
      });

      const reader = response.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let aiMessage = { text: '', sender: 'ai' };
      let firstChunk = true;

      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }
        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');
        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.substring(6);
            if (data.trim() === '[DONE]') {
              break;
            }
            const parsed = JSON.parse(data);
            if (parsed.choices && parsed.choices[0].delta.content) {
              if (firstChunk) {
                aiMessage.text = parsed.choices[0].delta.content;
                setMessages((prevMessages) => [...prevMessages, aiMessage]);
                firstChunk = false;
              } else {
                aiMessage.text += parsed.choices[0].delta.content;
                setMessages((prevMessages) => [...prevMessages.slice(0, -1), aiMessage]);
              }
            }
          }
        }
      }
    } catch (error) {
      console.error('Error fetching AI response:', error);
      const errorMessage = { text: 'Error fetching response from AI.', sender: 'ai' };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    }
  };

  return (
    <div className="chat-page">
      <div className="messages-container">
        {messages.map((msg, index) => (
          <Message key={index} message={msg} />
        ))}
      </div>
      <ChatInput onSendMessage={handleSendMessage} />
    </div>
  );
};

export default ChatPage;
