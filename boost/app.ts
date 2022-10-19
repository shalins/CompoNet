import path from "path";
import express from "express";
import log from "loglevel";
import { Pool } from "pg";
import { generateQuery } from "./client/src/utils/queries";

const host = "ec2-34-233-115-14.compute-1.amazonaws.com:5432";
const database = "dfu56m15dkhh46";
const user = "pgyrjmstmyerfk";
const password =
  "228fcbba14e9d2bf362fcaa29cabe1106cc8dba00605f45ee25e810194309fd4";

const pool = new Pool({
  max: 20,
  connectionString: `postgres://${user}:${password}@${host}/${database}`,
  idleTimeoutMillis: 30000,
  ssl: {
    rejectUnauthorized: false,
  },
});

const toArray = (data: any) => {
  return Array.isArray(data) ? data : [data];
};

const fetchData = async (req: any, res: any) => {
  try {
    const client = await pool.connect();
    const categories = toArray(req.query.categories);
    const attributes = toArray(req.query.attributes);
    let response: { [key: string]: any } = {};
    for (const category of categories) {
      const query = generateQuery(category, attributes);
      const result = await client.query(query);
      response[category] = result?.rows;
    }

    res.send(response);
    client.release();
  } catch (error) {
    res.status(400).send(error);
  }
};

// Create an environment variable called `LOG_LEVEL` to set the log level.
if (process.env.LOG_LEVEL) {
  log.setLevel(process.env.LOG_LEVEL as log.LogLevelDesc);
}

const app = express();
const port = process.env.PORT || 5555;

app.get("/api", fetchData);

// Listen on the specified port.
const server = app.listen(port, () => {
  console.log(`Signaling Server Listening on Port ${port}`);
});


// Have node serve the files for our built React app
app.use(express.static(path.resolve(__dirname, './client/build')));

// If we don't recognize the route, render the React app
app.get('*', (req, res) => {
	res.sendFile(path.resolve(__dirname, './client/build', 'index.html'));
});

