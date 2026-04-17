import mongoose from 'mongoose';
import { config } from '../config/config';

function buildMongoUri(): string {
  const username = encodeURIComponent(config.mongodb.USER);
  const password = encodeURIComponent(config.mongodb.PASSWD);
  const authPart =
    config.mongodb.USER && config.mongodb.PASSWD
      ? `${username}:${password}@`
      : '';

  const query = new URLSearchParams();
  if (config.mongodb.AUTHSOURCE) {
    query.set('authSource', config.mongodb.AUTHSOURCE);
  }
  if (config.mongodb.REPLICASET) {
    query.set('replicaSet', config.mongodb.REPLICASET);
  }

  const queryString = query.toString();
  return `mongodb://${authPart}${config.mongodb.HOST}/${config.mongodb.DATABASE}${
    queryString ? `?${queryString}` : ''
  }`;
}

/**
 * 连接 MongoDB 数据库
 */
export const connectMongoDB = async (): Promise<void> => {
  try {
    if (mongoose.connection.readyState === 1) {
      return;
    }

    await mongoose.connect(buildMongoUri(), {
      dbName: config.mongodb.DATABASE,
      serverSelectionTimeoutMS: 2_000,
      minPoolSize: 1,
      maxPoolSize: 20,
    });
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('Failed to connect to MongoDB:', error);
    throw error;
  }
};

/**
 * 断开 MongoDB 连接
 */
export const disconnectMongoDB = async (): Promise<void> => {
  try {
    if (mongoose.connection.readyState === 0) {
      return;
    }
    await mongoose.disconnect();
    console.log('MongoDB disconnected successfully');
  } catch (error) {
    console.error('Failed to disconnect from MongoDB:', error);
    throw error;
  }
};

/**
 * 获取 MongoDB 连接状态
 */
export const getMongoDBConnectionState = (): string => {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };

  return states[mongoose.connection.readyState as keyof typeof states] || 'unknown';
};
