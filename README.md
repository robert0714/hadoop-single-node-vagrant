# hadoop-single-node-vagrant

I started this project to be able to set up a simple, working Hadoop environment in minutes and be able recreate the environment without any hassle when I messed up. So I ended up with [Vagrant](http://www.vagrantup.com "Vagrant"):

>Vagrant provides easy to configure, reproducible, and portable work environments built on top of industry-standard technology and controlled by a single consistent workflow to help maximize the productivity and flexibility of you and your team. - [Why Vagrant?](http://docs.vagrantup.com/v2/why-vagrant/index.html "Vagrant Docs: Why Vagrant?")

You can find the code and README at the GitHub repo [hadoop-single-node-vagrant](https://github.com/baswenneker/hadoop-single-node-vagrant).

Setting up the single node hadoop environment is as easy as:

{% highlight bash %}
$ git clone https://github.com/baswenneker/hadoop-single-node-vagrant
$ vagrant up
{% endhighlight %}

The first command creates a folder *hadoop-single-node-vagrant* in the current directory and downloads the project files from the git repository. The `vagrant up` command provisions the Hadoop environment. 

During the provisioning process we created a user called *hduser* which we use to execute Hadoop commands. To use the box we have to ssh into it using: 

{% highlight bash %}
$ vagrant ssh -- -l hduser
{% endhighlight %}

The password of *hduser* is `hduser`.
You're good to go!

## Taking the Hadoop for a testdrive
Of course you want to see some action. We'll use the [Hadoop wordcount](http://hadoop.apache.org/docs/r1.2.1/mapred_tutorial.html "Hadoop Wordcount Example Tutorial") example to show off to your friends. 

#### Start HDFS and Yarn
First things first, let's start HDFS and Yarn.

{% highlight bash %}
$ start-dfs.sh
$ start-yarn.sh
{% endhighlight %}

To check if all nodes are up and running use `jps` and see if the output is about the same as below:

{% highlight bash %}
$ jps
11261 NameNode
11842 Jps
11365 DataNode
11813 NodeManager
11708 ResourceManager
11542 SecondaryNameNode
{% endhighlight %}

You can also check the health of Hadoop by browsing to [http://192.168.33.10:50070/](http://192.168.33.10:50070/) on the host machine.

#### Create the input directory and wordcount file in HDFS
Create the directory that contains the input files of which the words are counted (-p creates the full path). For more information about the HDFS Shell commands, see the [Hadoop File System Shell Guide](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/FileSystemShell.html "Hadoop File System Shell Guide")
    
{% highlight bash %}
$ hdfs dfs -mkdir -p /tmp/testing/wordcount_in
{% endhighlight %}

Create a sample text file that is counted:

{% highlight bash %}    
$ echo "Hello World <> Hello Hadoop" >> sample.txt
{% endhighlight %}

Copy the sample text to *wordcount_in* folder we just created on the HDFS filesystem.

{% highlight bash %} 
$ hdfs dfs -copyFromLocal sample.txt /tmp/testing/wordcount_in/
{% endhighlight %}

Just to make sure, check if your file is copied, use:
    
{% highlight bash %} 
$ hdfs dfs -ls /tmp/testing/wordcount_in
Found 1 items
-rw-r--r--  1 hduser  supergroup 38 2014-07-09 09:48 /tmp/testing/wordcount_in/sample.txt
{% endhighlight %}

#### Run the wordcount example
Now we're ready to let Hadoop take care of counting the words:

{% highlight bash %} 
$ hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /tmp/testing/wordcount_in /tmp/testing/wordcount_out
{% endhighlight %}

You should be able to beat Hadoop by doing the wordcount yourself, but hey you're a geek and Hadoop is awesome, so we use Hadoop. While you're waiting for Hadoop to finish, why not check the cluster status [http://192.168.33.10:8088/cluster](http://192.168.33.10:8088/cluster)?

To check the results afterwards:

{% highlight bash %} 
$ hdfs dfs -ls /tmp/testing/wordcount_out/
Found 2 items
-rw-r--r--  1 hduser supergroup  0 2014-07-09 11:11 /tmp/testing/wordcount_out/_SUCCESS
-rw-r--r--  1 hduser supergroup  84 2014-07-09 11:11 /tmp/testing/wordcount_out/part-r-00000
{% endhighlight %}

Now let's see if Hadoop came up with the right answer.

{% highlight bash %} 
$ hdfs dfs -cat /tmp/testing/wordcount_out/part-r-00000
    <>      1
    Hadoop  1
    Hello   2
    World   1
{% endhighlight %}
Wow!

## Some tips
If you messed up the box you can destroy and recreate the box by entering the following commands on the host machine:

    $ vagrant destroy
    $ vagrant up

## Provisioning
In order to save bandwidth and time the provisioning script downloads and store the Hadoop tarball in the shared directory (project folder on the host machine and /vagrant on the guest machine). If the download fails for some reason, delete the tarball and rerun vagrant provision.

## Troubleshooting
You might get the following warning message every now and then:

    WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable

This does no harm and can be ignored. For a fix, see http://stackoverflow.com/questions/19943766/hadoop-unable-to-load-native-hadoop-library-for-your-platform-error-on-centos.