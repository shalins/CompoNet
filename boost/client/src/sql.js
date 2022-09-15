// db.js
import React from 'react';
import postgres from 'postgres'

const sql = postgres({
  "host": "localhost",
  "port": 5432,
  "user": "shalinshah",
  "database": "test1",
});

export default sql
