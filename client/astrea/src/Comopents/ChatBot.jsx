import React, { useState, useEffect, useRef } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchResponses } from '../Redux/Actions';
import './ChatBot.css';
import flowData from './flow.json';
import astreaImage from './ASTREA.jpeg';

const Chatbot = () => {
  const responses = useSelector((state) => state.responses);
  const dispatch = useDispatch();
  const [userInput, setUserInput] = useState('');
  const [conversation, setConversation] = useState([]);
  const [currentFlow, setCurrentFlow] = useState(null);
  const [isBotOnline, setIsBotOnline] = useState(false);
  const onlineIndicatorRef = useRef(null);
  const [conversationProfiles, setConversationProfiles] = useState({
    bot: {
      image: astreaImage,
      label: 'Astrea',
     
    },
  });

  useEffect(() => {
    if (conversation.length > 0) {
      setIsBotOnline(true);
      onlineIndicatorRef.current.classList.add('sent');
    }
  }, [conversation]);

  useEffect(() => {
    if (responses.length > 0) {
      const lastResponse = responses[responses.length - 1];
      setConversation((prevConversation) => [
        ...prevConversation,
        { type: 'bot', message: lastResponse.respuesta },
      ]);
    }
  }, [responses]);

  const handleInputChange = (event) => {
    setUserInput(event.target.value);
  };

  const handleSendClick = async () => {
    const userMessage = userInput;
    setConversation((prevConversation) => [
      ...prevConversation,
      { type: 'user', message: userMessage },
    ]);
    setConversationProfiles((prevProfiles) => ({
      ...prevProfiles,
      user: {
       
        label: '',
      },
    }));
    try {
      const response = await dispatch(fetchResponses(userInput));
      console.log('Response:', response);

      if (response) {
        const flowPrincipal = response.flowPrincipal;
        console.log('Flow Principal:', flowPrincipal);

        const flow = findFlow(flowPrincipal, userMessage, flowData);
        if (flow) {
          setCurrentFlow(flow);
          setConversation((prevConversation) => [
            ...prevConversation,
            { type: 'bot', message: flow.response },
          ]);
        } else {
          setConversation((prevConversation) => [
            ...prevConversation,
            { type: 'bot', message: "I don't understand your question" },
          ]);
        }
      } else {
        console.error('Error fetching responses:', response);
      }
    } catch (error) {
      console.error('Error fetching responses:', error);
    }

    setUserInput('');
  };

  const findFlow = (flowPrincipal, userMessage, flowData) => {
    console.log('Finding flow for:', flowPrincipal, userMessage);
    for (const flow of Object.values(flowData)) {
      console.log('Checking flow:', flow);
      if (flow.keywords && flow.keywords.some((keyword) => userMessage.toLowerCase().includes(keyword))) {
        console.log('Flow matches:', flow);
        return flow;
      }
    }
    console.log('No flow found');
    return null;
  };

  return (
    <div className="chatbot-container">
      <div className="chatbot-header">
        <img
          src={require('./logo astrea 5.png')}
          alt="Chatbot Logo"
          className="chatbot-profile"
        />
        <div className="online-status">
          {isBotOnline ? (
            <div ref={onlineIndicatorRef} className="online-indicator glowing sent"></div>
          ) : (
            <div ref={onlineIndicatorRef} className="online-indicator"></div>
          )}
          <span className="online-label">Online</span>
        </div>
      </div>
      <div className="chatbot-conversation" id="conversation-container">
        <div className="chatbot-messages-wrapper">
          <div className="chatbot-messages">
            {conversation.map((message, index) => (
              <div key={index} className={`chatbot-message ${message.type === 'bot' ? 'bot-message' : 'user-message'}`}>
                {message.type === 'bot' && (
                  <div className="conversation-profile">
                    <img
                      src={conversationProfiles.bot.image}
                      alt={conversationProfiles.bot.label}
                      className="chatbot-profile-image"
                    />
                    <span className="conversation-label">{conversationProfiles.bot.label}</span>
                  </div>
                )}
                <div className="conversation-bubble">
                  <label>{message.type === 'bot' ? '' : 'You:'}</label>
                  <p>{message.message}</p>
                </div>
              </div>
            ))}
            {currentFlow && (
              <div>
                <p>{currentFlow.name}</p>
              </div>
            )}
          </div>
        </div>
      </div>
      <div id="chatbot-input-container">
        <input
          type="text"
          id="user-input"
          value={userInput}
          onChange={handleInputChange}
          placeholder="Escribe un mensaje..."
        />
        <button id="chatbot-send-button" onClick={handleSendClick}>
          Enviar
        </button>
      </div>
    </div>
  );
};

export default Chatbot;
