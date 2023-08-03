import os

directory = './'  # directory where images are stored
extension = '.JPG'  # extension of the images

# Get a list of all the image files in the directory
image_files = [f for f in os.listdir(directory) if f.endswith(extension)]

# Sort the files
image_files.sort()

for i, filename in enumerate(image_files, start=1):
    # Generate new name for the file
    new_name = f'{i}{extension}'

    # Rename the file
    os.rename(os.path.join(directory, filename), os.path.join(directory, new_name))

print("Renaming complete.")
