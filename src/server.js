import express from 'express';
import createHttpTerminator from 'lil-http-terminator';
import { cluster, generalTask, htmlTask } from './cluster.js';

const app = express();
const port = process.env.PORT || 3000;

app.get('/general', async (req, res) => {
  if (!req.query.url) {
    return res.status(400).json({ message: 'Missing parameter' });
  }
  try {
    const data = await cluster.execute(req.query, generalTask);
    return res.json(data);
  } catch (error) {
    return res.status(404).json({ name: error.name, message: error.message });
  }
});

app.get('/html', async (req, res) => {
  if (!req.query.url || !req.query.selector) {
    return res.status(400).json({ message: 'Missing parameters' });
  }
  try {
    const html = await cluster.execute(req.query, htmlTask);
    return res.send(html);
  } catch (err) {
    return res.status(404).json({ name: err.name, message: err.message });
  }
});

app.all('*', (req, res) => {
  res.status(400).json({ message: 'Incorrect path or method specified' });
});

app.use((err, req, res, next) => {
  console.error(err);
  const status = err.status || 500;
  const message = err.message || err;
  res.status(status).json({ message });
});

const server = app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

async function shutdown() {
  console.log('Shutting down...');
  const httpTerminator = createHttpTerminator({ server });
  await httpTerminator.terminate();
  await cluster.idle();
  await cluster.close();
  process.exit();
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
