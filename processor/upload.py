import psycopg2 as ps
from postgres_csv_uploader.uploader import PostgresCSVUploader

JSON_DIR = "./_raw_json"
CSV_DIR = "./_raw_csv"
CSV_COMBINED = "combined.csv"
CSV_FINAL = "final.csv"

host = "ec2-34-233-115-14.compute-1.amazonaws.com"
port = 5432
database = "dfu56m15dkhh46"
user = "pgyrjmstmyerfk"
password = "228fcbba14e9d2bf362fcaa29cabe1106cc8dba00605f45ee25e810194309fd4"

conn = ps.connect(host=host, user=user, password=password, port=port, database=database)

uploader = PostgresCSVUploader(conn)
uploader.upload(f"{CSV_DIR}/{CSV_FINAL}", CSV_FINAL.split(".")[0])
