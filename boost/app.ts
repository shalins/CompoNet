import express from "express";
import log from "loglevel";
import { Pool } from "pg";

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

const get = async (req: any, res: any) => {
  try {
    const client = await pool.connect();
    const sql = `SELECT part_specs_capacitance_display_value,
				 part_median_price_1000_converted_price
				 FROM public.all 
				 WHERE part_category_id=$1 AND
				 part_specs_capacitance_display_value IS NOT NULL AND
				 part_median_price_1000_converted_price IS NOT NULL AND
				 part_median_price_1000_converted_price != $2 AND
				 part_specs_capacitance_display_value != $2`;
    console.log("this is being logged", req.query.component);
    const component = req.query.component;
    const rows = (await client.query(sql, [component, "nan"]))?.rows;
    // const data = processData(rows);

    res.send(rows);
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

app.get("/api", (req, res) => {
  res.json({ message: "Hello from server!" });
});

app.get("/desc", get);

// Listen on the specified port.
const server = app.listen(port, () => {
  console.log(`Signaling Server Listening on Port ${port}`);
});
