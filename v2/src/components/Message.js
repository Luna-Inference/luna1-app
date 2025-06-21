import React from 'react';
import ReactMarkdown from 'react-markdown';
import './Message.css';

const Message = ({ message }) => {
  const { text, sender } = message;
  return (
    <div className={`message ${sender}`}>
      <ReactMarkdown>{text}</ReactMarkdown>
    </div>
  );
};

export default Message;
