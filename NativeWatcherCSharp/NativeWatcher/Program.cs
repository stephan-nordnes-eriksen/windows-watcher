using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Security.Permissions;
using System.Collections;

namespace NativeWatcher
{
    public class Watcher
    {
        //public static System.IO.FileSystemWatcher theWatcher;//Possibly add hash here to enable listening to multiple folders.

        public static Dictionary<string, System.IO.FileSystemWatcher> watchers = new Dictionary<string, FileSystemWatcher>();
    }   

    public class Startup
    {
        public async Task<object> Invoke(dynamic input)
        {
            string path = (string)input.path;
            if ((bool)input.stopping)
            {
                if ((bool)input.stoppingAll)
                {
                    foreach (KeyValuePair<string, System.IO.FileSystemWatcher> entry in Watcher.watchers)
	                {
                        entry.Value.EnableRaisingEvents = false;
	                }
                    Watcher.watchers.Clear();
                }
                else
                {
                    if (Watcher.watchers.ContainsKey(path))
                    {
                        Watcher.watchers[path].EnableRaisingEvents = false;
                        Watcher.watchers[path].Dispose();
                        Watcher.watchers.Remove(path);
                    }
                }
                //Watcher.theWatcher.EnableRaisingEvents = false;
                return false;
            }

            if (Watcher.watchers.ContainsKey(path))
            {
                Watcher.watchers[path].EnableRaisingEvents = false;
                Watcher.watchers[path].Dispose();
                Watcher.watchers.Remove(path);
            }
            var responseCallback = (System.Func<object, Task<object>>)input.responseCallback;

            Watcher.watchers[path] = new System.IO.FileSystemWatcher();
            Watcher.watchers[path].NotifyFilter = System.IO.NotifyFilters.LastAccess | System.IO.NotifyFilters.LastWrite
            | System.IO.NotifyFilters.FileName | System.IO.NotifyFilters.DirectoryName;
            Watcher.watchers[path].IncludeSubdirectories = (bool)input.recursive;
            Watcher.watchers[path].Path = (string)input.path;
            //System.Console.WriteLine("Path:");
            //System.Console.WriteLine(Watcher.watchers[path].Path);
            Watcher.watchers[path].Filter = (string)input.filter;
            Watcher.watchers[path].Changed += delegate(object sender, System.IO.FileSystemEventArgs e)
            {
               // System.Console.WriteLine("Changed" + Watcher.watchers.Count);
                responseCallback(new string[] { "Changed", e.FullPath });
            };
            Watcher.watchers[path].Created += delegate(object sender, System.IO.FileSystemEventArgs e)
            {
               // System.Console.WriteLine("Created" + Watcher.watchers.Count);
                responseCallback(new string[] { "Created", e.FullPath });
            };
            Watcher.watchers[path].Deleted += delegate(object sender, System.IO.FileSystemEventArgs e)
            {
               // System.Console.WriteLine("Deleted"+ Watcher.watchers.Count);
                responseCallback(new string[] { "Deleted", e.FullPath });
            };
            Watcher.watchers[path].Renamed += delegate(object sender, System.IO.RenamedEventArgs e)
            {
               // System.Console.WriteLine("Rename" + Watcher.watchers.Count);
                responseCallback(new string[] { "Rename", e.OldFullPath, e.FullPath });
            };

            // Begin watching
            Watcher.watchers[path].EnableRaisingEvents = true;

            return true;
        }
    }
}
