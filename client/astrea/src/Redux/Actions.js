export const SET_RESPONSES = 'SET_RESPONSES';
export const FETCH_RESPONSES_PENDING = 'FETCH_RESPONSES_PENDING';
export const FETCH_RESPONSES_SUCCESS = 'FETCH_RESPONSES_SUCCESS';
export const FETCH_RESPONSES_ERROR = 'FETCH_RESPONSES_ERROR';

export const setResponses = (responses) => ({
  type: SET_RESPONSES,
  payload: responses,
});

export const fetchResponsesPending = () => ({
  type: FETCH_RESPONSES_PENDING,
});

export const fetchResponsesSuccess = (data) => ({
  type: FETCH_RESPONSES_SUCCESS,
  payload: data,
});

export const fetchResponsesError = (error) => ({
  type: FETCH_RESPONSES_ERROR,
  payload: error,
});
export const fetchResponses = (userInput) => {
  return async (dispatch) => {
    try {
      const response = await fetch('http://localhost:3001/bot/data');
      const data = await response.json();
      dispatch({ type: 'FETCH_RESPONSES_SUCCESS', payload: data });
      return data; // Devuelve la respuesta del servidor
    } catch (error) {
      dispatch({ type: 'FETCH_RESPONSES_ERROR', payload: error });
      return error; // Devuelve el error si ocurre
    }
  };
};