import React from 'react';
import ReactDOM from 'react-dom/client'; // Correct import for React 18+
import { Provider } from 'react-redux';
import { createStore } from 'redux'; // Ensure createStore is imported from 'redux'
import rootReducer from './Redux/Reducer'; // Ensure the path is correct
import App from './App';

import reportWebVitals from './reportWebVitals';

// Create the Redux store
const store = createStore(rootReducer);

// Create the root element and render the app
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <Provider store={store}>
    <App />

  </Provider>
);

// Report web vitals (optional)
reportWebVitals();
