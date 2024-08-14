import {
    SET_RESPONSES,
    FETCH_RESPONSES_PENDING,
    FETCH_RESPONSES_SUCCESS,
    FETCH_RESPONSES_ERROR,
  } from './Actions';
  
  const initialState = {
    responses: [],
    initialResponses: [], // New property to store initial responses
    loading: false,
    error: null,
  };
  
  const responsesReducer = (state = initialState, action) => {
    switch (action.type) {
      case FETCH_RESPONSES_PENDING:
        return {
          ...state,
          loading: true,
          error: null,
        };
      case FETCH_RESPONSES_SUCCESS:
        return {
          ...state,
          loading: false,
          initialResponses: action.payload, // Store initial responses
          responses: action.payload,
        };
      case FETCH_RESPONSES_ERROR:
        return {
          ...state,
          loading: false,
          error: action.payload,
        };
      case SET_RESPONSES:
        return {
          ...state,
          responses: action.payload,
        };
      default:
        return state;
    }
  };
  
  export default responsesReducer;
  