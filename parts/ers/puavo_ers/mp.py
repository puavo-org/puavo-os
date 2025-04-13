# Standard library imports
import multiprocessing
import queue


def run_tasks_until_one_dies(funcs):
    results = []

    result_queue = multiprocessing.Queue()

    procs = [
        multiprocessing.Process(target=func, kwargs={"result_queue": result_queue})
        for func in funcs
    ]

    for p in procs:
        p.start()

    while True:
        try:
            result = result_queue.get(timeout=2)
        except queue.Empty:
            pass
        else:
            results.append(result)

        if all(p.is_alive() for p in procs):
            continue

        break

    for p in procs:
        p.terminate()

    for p in procs:
        p.join(timeout=2)
        p.kill()
        p.join()

    while True:
        try:
            result = result_queue.get(timeout=0)
        except queue.Empty:
            break
        results.append(result)

    return [p.exitcode for p in procs], results
