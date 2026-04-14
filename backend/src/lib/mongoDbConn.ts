import mongoose, { type ConnectOptions, type Connection } from 'mongoose';

export class MongoDbConn {
  private readonly db: {
    HOST: string;
    USER: string;
    PASSWD: string;
    DATABASE: string;
    authSource: string;
    replicaSet: string;
  };

  constructor({
    host,
    user,
    password,
    database,
    authSource = 'admin',
    replicaSet = '',
  }: {
    host: string;
    user: string;
    password: string;
    database: string;
    authSource?: string;
    replicaSet?: string;
  }) {
    this.db = {
      HOST: host,
      USER: user,
      PASSWD: password,
      DATABASE: database,
      authSource,
      replicaSet,
    };
  }

  connect(): Connection {
    const opts: ConnectOptions = {
      serverSelectionTimeoutMS: 2 * 1000,
      minPoolSize: 1,
      maxPoolSize: 20,
      authSource: this.db.authSource,
    };

    if (this.db.replicaSet) {
      opts.replicaSet = this.db.replicaSet;
    }

    return mongoose.createConnection(
      `mongodb://${this.db.USER}:${this.db.PASSWD}@${this.db.HOST}/${this.db.DATABASE}`,
      opts
    );
  }
}
