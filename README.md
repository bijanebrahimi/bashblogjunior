BashBlogJuniour
============

An improvement for bashblog script with markup language support like Markdown and many new features

## Usage

Download the script and run it

    $ ./bbj.sh

## Configuration

Markup Language Configuration

    #~ Markup Language
    global_markup="markdown"
    global_markdown_application="/usr/bin/markdown"
    global_markdown_cmd="$global_markdown_application --html4tags"
    global_markdown_extension="md"
    
Blog Directories Configuration

    #~ Directories Configuration
    global_post_directory=""
    global_temp_directory="/tmp/"
    global_temp_prefix=".bbj-"
    global_template_directory="drafts/"

Disqus Commenting System

	global_disqus_shortname


## Manual

To see the Manual usage just run the script without any arguments

    $ ./bbj.sh
    BashBlogImproved v0.0.1
    Usage: ./bbj.sh command [filename]
    
    Commands:
		init               creates initial files in the current path
		post [sourcefile]  insert a new blog post, or the SOURCEFILE of a Template to continue editing it
		edit [sourcefile]  edit an already created SOURCEFILE
		rm   [sourcefile]  remove blog entry
		rebuild [option]   regenerates all/specific pages
						   option=[index|archive|posts|rss|css]
		reset              deletes blog-generated files. Use with a lot of caution and back up first!
		list               list all entries. Useful for debug
		backup [output]    backup sourcefiles
    
    For more information please open ./bbj.sh in a code editor and read the header and comments

### Initial

Initialize the blog by passing the **init** argument. This simply create two CSS files in the current directory.

    $ ./bbj.sh init
    Initializing  ... finished

### Reset

To delete all the auto-generated files, pass the **reset** argument. This removes all the files created by the script.

    $ ./bbj.sh reset
    Are you sure you want to delete all blog entries? Please write "Yes, I am!"
    Deleted all posts, stylesheets and feeds.

### Post

To create a new post pass the **post** argument. By default, nano will be opened. You can change this in the script.
Type in your first post content and close the editor. The first line is the blog title and rest will be its content. Save the document and close the editor. The rest is interactive. You can choose to view a preview and decide whether it needs further improvements or not. When finished, post it by pressing **P**. Next is to rebuild the index, archive, and RSS feed pages. The script asks you to rebuild them automatically after posting new entry (although you can do it manually, see **rebuild**).
You can [download](bashblog-improved.md) this post markdown sourcefile to see how it works 

### Rebuild

You can also rebuild the files manually by passing the **rebuild** argument. Without any more argument, it rebuilds all the files necessary. but you can choose to rebuild specific files. Look at the usage section for more details.

    $ ./bbj.sh rebuild
    $ ./bbj.sh rebuild css

### Edit

You can edit an entry by passing **edit** and name of the source/template file. If you're using the default markup, the sourcefiles extensions will be **.md**

    $ ./bbj.sh edit bashblog-improved.md

Don't forget to rebuild the files after changing an entry

### Remove

You can delete the post by using **remove** option. After verification, it deletes the post source file and html file and offers you to do automatic rebuild. This is the best way to delete an unwanted post.

### Backup

The only files you nedd to keep it in your backup is the markup language source files. Use **backup** to store them or do it manually. Later you can use the rebuild command to build the html files from markdown files.


