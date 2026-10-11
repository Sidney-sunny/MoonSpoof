import { createRoot } from 'react-dom/client';
import '@fontsource/manrope/latin-400.css';
import '@fontsource/manrope/latin-500.css';
import '@fontsource/manrope/latin-600.css';
import '@fontsource/manrope/latin-700.css';
import './style.css';
import App from './App.jsx';
import { I18nProvider } from './i18n.jsx';

createRoot(document.getElementById('root')).render(<I18nProvider><App /></I18nProvider>);
