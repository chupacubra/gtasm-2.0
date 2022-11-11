local OS = OS;

include("sv_commands.lua");

function OS:GetName()
	return "PersonalOS(With gTASM)";
end;

function OS:GetUniqueID()
	return "ptsm";
end;

function OS:GetWarmUpText()
	return {
		"  ___ ___ ___  ___  ___  _  _   _   _    ",
		" | _ \\ __| _ \\/ __|/ _ \\| \\| | /_\\ | |   ",
		" |  _/ _||   /\\__ \\ (_) | .` |/ _ \\| |__ ",
		" |_| |___|_|_\\|___/\\___/|_|\\_/_/ \\_\\____|",
		" OS Personal With gTASM pack!"
	};
end;