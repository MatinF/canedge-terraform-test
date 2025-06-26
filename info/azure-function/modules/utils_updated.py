def decode_log_file(decoder, tmp_input_dir, tmp_output_dir, logger):
    import subprocess, os, shutil
    
    fs_logfiles_path = tmp_input_dir / "logfiles" 
    
    # Check if the logfiles folder contains any files
    logfiles = list(fs_logfiles_path.glob('*.*'))
    if not logfiles:
        logger.error("No log files available for decoding")
        return False
        
    shutil.copy("./" + decoder, tmp_input_dir)
    subprocess.run([os.path.join(tmp_input_dir, decoder), "-v"], cwd=str(tmp_input_dir),)
    subprocess_result = subprocess.run([os.path.join(tmp_input_dir, decoder),"-i",str(fs_logfiles_path),"-O",str(tmp_output_dir), "--verbosity=1","-X",],cwd=str(tmp_input_dir),)
            
    if subprocess_result.returncode != 0:
        logger.error(f"MF4 decoding failed (returncode {subprocess_result.returncode})")
        result = False 
    else:
        logger.info(f"MF4 decoding created {len(list(tmp_output_dir.rglob('*.*'))) } Parquet files")
        result = True 

    return result
