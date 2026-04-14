import { MongoDbConn } from '../lib/mongoDbConn';
import { config } from '../config/config';

const mongoDbConn = new MongoDbConn({
  host: config.mongodb.HOST,
  user: config.mongodb.USER,
  password: config.mongodb.PASSWD,
  database: config.mongodb.DATABASE,
  authSource: config.mongodb.AUTHSOURCE,
  replicaSet: config.mongodb.REPLICASET,
});

export const dbConn = mongoDbConn.connect();
