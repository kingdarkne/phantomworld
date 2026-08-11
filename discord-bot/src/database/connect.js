const mongoose = require('mongoose');
const chalk = require('chalk');

async function connect() {
  const uri = process.env.MONGO_TOKEN || process.env.MONGODB_URI;
  if (!uri) {
    console.log(
      chalk.red('[Phantom World] MONGO_TOKEN is required — create a free cluster at MongoDB Atlas and paste the connection string in .env'),
    );
    process.exit(1);
  }

  mongoose.set('strictQuery', false);

  console.log(
    chalk.blue(chalk.bold('Database')),
    chalk.white('>>'),
    chalk.red('MongoDB'),
    chalk.green('is connecting...'),
  );

  try {
    await mongoose.connect(uri);
    console.log(
      chalk.blue(chalk.bold('Database')),
      chalk.white('>>'),
      chalk.red('MongoDB'),
      chalk.green('is ready!'),
    );
  } catch (err) {
    console.log(
      chalk.red('[ERROR]'),
      chalk.white('>>'),
      chalk.red('MongoDB'),
      chalk.white('>>'),
      chalk.red('Failed to connect!'),
      chalk.white('>>'),
      chalk.red(`Error: ${err.message}`),
    );
    console.log(chalk.red('Exiting...'));
    process.exit(1);
  }

  mongoose.connection.on('error', (err) => {
    console.log(
      chalk.red('[ERROR]'),
      chalk.white('>>'),
      chalk.red('Database'),
      chalk.white('>>'),
      chalk.red(err.message),
    );
  });
}

module.exports = async () => connect();
