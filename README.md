# Spectre
> Yo, dawg, I heard you like installing scripts! So, I made an install script for your self-installing script.

Spectre is a dead-simple shell script that bootstraps self-installing apps in an ever-so-slightly more standardized manner.

## Bootstraps... What now?
If you're a Linux user, I'm sure you've seen them. It's these types of apps that - instead of downloading them from a repo (like so: `apt install some-app`) as you'd normally do - are downloaded by a special script that you curl and then pipe into Bash (as in `curl -fsSL https://some.app/install.sh | bash`). Examples of such apps include [Bun](https://bun.sh/) and [Starship Prompt](https://starship.rs/guide/#%F0%9F%9A%80-installation) (although the latter also supports distro packages). We refer to these as self-installing because they provide an installer by themselves, rather than relying on your OS - though admittedly, the install script that you curl is usually separate from the main app. That makes it not truly self-installing, as some extra piece of software is necessary for the installation process (it just so happens that said software is tightly coupled to the app it installs, as opposed to your distro packages which - by their very nature - must be universal). This split usually occurs because the app is written in a more humane language than Bash (for instance, Bun was made in Zig and Starship in Rust) that can't be understood by the standard Bash interpreter. However, if the app itself is a Bash script, you might feel compelled to add an `install` subcommand, thus embedding the installer inside the app itself. That's what we call a „self-installing script” because the script literally installs itself.

This is exactly what we tried for [magic-sauce](https://github.com/Team-GhostLand/magic-sauce), but it didn't quite work out, sadly. To spare the details, we discovered that we needed a pre-download step in a separate script. That script - is the very Spectre you're looking at right now. And that also makes magic-sauce the 1st-ever instance of a so-called „Spectre app”.

## How does this bootstrapping work?

Spectre doesn't do much. Only 3 simple things, in fact! It:
* Creates a folder for your app in a standardized location.
* Downloads an archive containing either your app and its install script OR just your self-installing script - along with any assets that they may possibly require.
* Runs the `install` subcommand of said script.
* *there's a secret 4th thing that we'll talk about later*

You may wonder why does it even exist, then? After all, it's trivial to implement such functionality on your own:
* The script is already downloaded by curl and running (so there's no need to download it separately in a ZIP file, unlike what Spectre does).
* You can create your own folder via said script.
* The app (in case of a self-installing app and not a self-installing script) and any necessary assets can be `wget`ed into said folder by the aforementioned script.
* Any subcommands, if needed, can just be put inside the docs on your website, embedded within the installation one-liner command.

Indeed, Spectre isn't exactly hard to replicate on your own. You can easily get away with not using it - that's what we'd been doing for years now, after all. However, Spectre brings two key things to the table:
* The ability to operate on on-device ZIP files (the download step can be skipped in favour of unzipping a file already found on your machine). Admittedly, that can also be easily done without Spectre - but it'd take one extra step (get the archive -> unzip it -> run whatever script it contained, as opposed to: get the archive -> run Spectre on it). Also, Spectre lets you reverse the order (you can run Spectre first and it'll wait for the archive to appear - you can't do that with ZIP files, as (to my knowledge) `unzip` doesn't offer any way of waiting for a file).
* **STABILITY.** While this whole "using on-device or soon-to-be-on-device ZIP files"-thing is pretty niche and won't be useful for most (though it is crucial for magic-sauce, so there are at least some use cases), this one isn't. Most self-installing apps like to put their files Fuckknowswhere and then ask you to add their internal `./bin/` folder into your `$PATH`. This leads to a cluttered `home`/`var`/`opt`/root/wherever-else-they-decided-to-put-it directory and a multi-line `$PATH` export in your shell's RC file. We say: NO! All your Spectre apps can be found under `/var/spectre` (configurable) and as part of the installation process, binaries are symlinked into `/bin/` (also configurable). Indeed, to be considered a „Spectre app”, your project doesn't even need to depend on this script in any way. It can be a regular self-installing app/script. It just needs to follow some basic conventions that ensure consistency with other Spectre apps. Please refer to the next section to discover these conventions.

## How to use?
Like any other self-installing app: You curl Spectre and pipe it into Bash. In its most basic form, such a one-liner would look like this:

```sh
curl -fsSL https://raw.githubusercontent.com/Team-GhostLand/Spectre/master/universal-installer-scaffolding.sh | sudo -E bash
```

If ran like this, it would install magic-sauce as `/bin/minecraft` into `/var/spectre/ghostland` using the ARCHIVE strategy (what this means will be explained shortly). Of course, this is probably not what you want. Magic-sauce is an internal tool, after all. Thankfully, you can control the process using environment variables. In general, the place from where you copied your one-liner should already have them configured. For example:

```sh
export PROJECT_NAME="my-app" SCRIPT_NAME="installer" INSTALL_PATH="/bin/my-app" SOURCE="https://example.com/my-app.zip" && curl -fsSL https://raw.githubusercontent.com/Team-GhostLand/Spectre/master/universal-installer-scaffolding.sh | sudo -E bash
```

`SCRIPT_NAME` and `SOURCE` (or `GIT` or `GITHUB`, which are `SOURCE`'s counterparts when using Git repos instead of ZIP files) are provided by the app and shouldn't be messed with. The former will break if set to a wrong value, while the latter CAN be changed, but only if you know what you're doing, which we won't help you with here (read the script to figure out what they do).

As the end user, you should only concern yourself with `INSTALL_PATH` and `PROJECT_NAME` (only in case of name conflicts - otherwise, it's recommended to leave it as default). The latter will be explained shortly, while the former tells Spectre where to symlink the app's binary. If there are multiple binaries, they should be prefixed with it (as in: `$INSTALL_PATH` (eg. `/bin/app`) is the main binary and `$INSTALL_PATH-something` (eg. `/bin/app-something`) is the secondary one). Of course, Spectre doesn't actually symlink anything - that's the job of an install script that Spectre calls. But that doesn't mean that we don't do anything with this envar! Spectre replaces (via SED) any occurrence of `%INSTALL_PATH%` inside the aforementioned install script with the value of `$INSTALL_PATH`. This, in essence, means that your install script is permanently imbued with the knowledge of where the binary is located and can use this information for any future actions (like uninstalls or updates). That's the "secret 4th thing" done by Spectre that we mentioned some time ago.

There is one more environment variable that Spectre understands: `SPECTRE_PATH`. Projects should NEVER change in their one-liners, as this variable is supposed to be kept consistent across all Spectre apps on a given device (or for a given user, in case of rootless installs). That's because `SPECTRE_PATH` tells you where to store those apps. During installation, it's concatenated with `PROJECT_NAME`. For example,  `export PROJECT_NAME="my-app" SPECTRE_PATH="/var/spectre"` means `my-app` will be installed into `/var/spectre/my-app`. Coincidentally, `/var/spectre` is also the default value of `$SPECTRE_PATH`. By default, Spectre only works when ran as root, but changing `SPECTRE_PATH` to anything (even back to its default value) disables root checks so that you can point it at a directory somewhere in your `$HOME` (thus enabling a rootless install).

### What do these envars mean to me if I'm an application developer?
Depends on whether you want to build a Spectre-compliant app, or actually use our Spectre script. If it's the former, your job is easy:
* Store everything (both static assets/binaries and any kind of mutable state) inside `$SPECTRE_PATH/<your-project-name>`, while keeping in mind that if `$SPECTRE_PATH` is unset, it defaults to `/var/spectre`. Also, in case of a name conflict, warn the user about it and (if they really want to install your app twice) let them change your project's name.
* Symlink (not copy) your binary into the `/bin/` folder, while also allowing the user to change its name and location (you may use Spectre's `INSTALL_PATH` or some other mechanism). If you have multiple binaries, keep a common user-changeable prefix for all of them.

If it's the latter... Uhh... Idk, man. Read the script. Yeah, I wanted to explain here how everything works (including what are download strategies), but this README is already longer than the script itself. Consider it a TODO. I'll finish this documentation one day, but that's not today. Cheers!


## Q&A
*Note: this README is WIP. This section will be expanded here eventually.*
### Are you aware of that one XKCD comic?
Yes.

### Why the name Spectre?
Because this tool is part of GhostLand's suite, so we're keeping to the ghastly theme.

### Why is the Bash code so bad?
I wrote it like a set of simple shell commands, not like a program. When you execute something in your terminal, you don't really think of your command as a piece of application code, it's more like a UI action expressed through text. I wanted this script to feel the same way: just a list of UI actions taken one by one on your computer (that anyone can read from top to bottom and understand what's going on), as that's what Bash was made for. It's a pretty terrible programming language, to be honest. There is a reason why so many pre-processors exist for it. Trying to write app-like code in Bash results in a mess that cannot be comprehended by anyone but Bash wizards - even people who generally live in the terminal struggle with it. This is why I tried to limit Bash features as much as possible: no functions, only 2 loops (one of which has no content), and no positional arguments (relying on envars instead). Obviously, the trade-off is that we ended up with some awkward global state sharing, which gets confusing at times (to the point that I had to leave a comment explaining the origin of some environment variables). ~~ Yeah, anyway... All of that, plus some major Bash skill issues. Yes, I'm one of those people who live in the terminal, yet experience brain aneurysm when hit with a complex Bash script.~~