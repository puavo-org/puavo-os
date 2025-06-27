import { exec } from 'child_process';

export async function run(command: string): Promise<string> {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, _) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
}
