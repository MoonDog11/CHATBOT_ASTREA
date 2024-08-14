import { createStore, combineReducers, applyMiddleware, compose } from 'redux';
import { thunk } from 'redux-thunk';
import responsesReducer from '../Redux/Reducer'; // Ensure this path is correct

// Combine reducers
const rootReducer = combineReducers({
  responses: responsesReducer,
});

// Setup Redux DevTools if available
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

// Create the Redux store with thunk middleware and Redux DevTools support
const store = createStore(
  rootReducer,
  composeEnhancers(applyMiddleware(thunk))
);

export default store;
