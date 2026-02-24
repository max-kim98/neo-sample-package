import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import App from './App';
import * as api from './api/api';

jest.mock('./api/api');

afterEach(() => {
  jest.resetAllMocks();
});

test('renders package dashboard title', () => {
  render(<App />);
  expect(screen.getByRole('heading', { name: /package dashboard/i })).toBeInTheDocument();
});

test('renders backend interaction buttons', () => {
  render(<App />);
  expect(screen.getByRole('button', { name: /refresh health/i })).toBeInTheDocument();
  expect(screen.getByRole('button', { name: /send echo/i })).toBeInTheDocument();
});

test('refresh health loads health and version payloads', async () => {
  api.fetchHealth.mockResolvedValue({ status: 'ok', service: 'demo' });
  api.fetchVersion.mockResolvedValue({ name: 'demo', version: '0.1.0' });

  render(<App />);
  const user = userEvent.setup();
  await user.click(screen.getByRole('button', { name: /refresh health/i }));

  await waitFor(() => {
    expect(api.fetchHealth).toHaveBeenCalledTimes(1);
    expect(api.fetchVersion).toHaveBeenCalledTimes(1);
  });

  expect(screen.getByLabelText('health-response')).toBeInTheDocument();
});

test('send echo posts input message', async () => {
  api.sendEcho.mockResolvedValue({ message: 'hello package' });

  render(<App />);
  const user = userEvent.setup();
  await user.click(screen.getByRole('button', { name: /send echo/i }));

  await waitFor(() => {
    expect(api.sendEcho).toHaveBeenCalledWith('hello package');
  });

  expect(screen.getByLabelText('echo-response')).toBeInTheDocument();
});
