# SPARK and GNATprove

project_tools has partial SPARK coverage for reusable release-check helper APIs. The release command is:

```sh
alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check
```

This command is mandatory for every project_tools release and is run by `tools/bin/check_all`.

Current proof scope includes SPARK legality checks for public helper packages such as:

- `Project_Tools.Text`
- `Project_Tools.Files`
- `Project_Tools.Processes`
- `Project_Tools.Alire_Manifests` and child packages
- `Project_Tools.AUnit_Checks`
- `Project_Tools.Security_Corpus`
- `Project_Tools.Tree_Checks`

Some helper operations are intentionally ordinary Ada at runtime because they call filesystem, process, or directory traversal services. Keep new helpers small, deterministic, and status-oriented where practical so future proof coverage can grow without changing callers.
