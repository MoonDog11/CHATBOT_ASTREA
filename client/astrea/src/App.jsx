import React from 'react';
import { BrowserRouter,Routes, Route } from 'react-router-dom';
import ChatBot from './Comopents/ChatBot'; 

import { Provider } from 'react-redux';
import store from "./Redux/Store";

const App = () => {
  return (
    <Provider store={store}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<ChatBot />} />
       
          <Route />
        </Routes>
      </BrowserRouter>
    </Provider>
  );
};

export default App;