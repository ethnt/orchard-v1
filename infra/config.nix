{ pkgs, config, lib, ... }: {
  resource.local_file.test = {
    content = "foo!";
    filename = "foo.txt";
  };
}
