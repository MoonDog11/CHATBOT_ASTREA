import { Provider } from 'react-redux';
import store from './Redux/Store';

const ProviderComponent = ({ children }) => {
  return <Provider store={store}>{children}</Provider>;
};

export { ProviderComponent as Provider };