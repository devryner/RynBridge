import { Command } from 'commander';
import { initCommand } from './commands/init.js';
import { addCommand } from './commands/add.js';
import { generateCommand } from './commands/generate.js';
import { doctorCommand } from './commands/doctor.js';

const program = new Command();

program
  .name('rynbridge')
  .description('RynBridge CLI — scaffold, generate, and manage your bridge project')
  .version('0.3.0');

program.addCommand(initCommand);
program.addCommand(addCommand);
program.addCommand(generateCommand);
program.addCommand(doctorCommand);

program.parse();
