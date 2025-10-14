import { execFile } from 'child_process';

export async function run(
  command: string,
  args: string[] = []
): Promise<string> {
  return new Promise((resolve, reject) => {
    execFile(command, args, (error, stdout, _) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
}
