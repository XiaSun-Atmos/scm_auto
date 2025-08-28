#!/bin/bash

# Step size and maximum index
step=10
max=199

for start in $(seq 0 $step $max); do
    end=$((start + step-1))
    if [ $end -gt $max ]; then
        end=$max
    fi

    # Collect valid folders
    folders=()
    for i in $(seq $start $end); do
        folder="lat_$i"
        if [ -d "$folder" ]; then
            folders+=("$folder")
        fi
    done

    if [ ${#folders[@]} -eq 0 ]; then
        continue
    fi

    tar_name="lat_${start}_${end}.tar.gz"
    echo "Creating $tar_name with: ${folders[*]}"
    tar -czf "$tar_name" "${folders[@]}"
    if [ $? -eq 0 ]; then
	            echo "Successfully created $tar_name. Deleting original folders..."
		            rm -rf "${folders[@]}"
			        else
					        echo "Tar failed for $tar_name. Keeping original folders."
						    fi


done

