$find_bytes = "80 78 05 00 0F 94 C1"
$patch_bytes = "C6 40 05 01 48 85 C9"

# -------------------------------------
# ----------- Dont edit below ---------
# -------------------------------------

# PS is SO slow for string manipulation, use C#
Add-Type -Language CSharp @"
using System;
namespace Powershell
{
    public class ByteManipulation
    {
        public string ByteArrayToString(byte[] ba)
        {
            return BitConverter.ToString(ba).Replace("-", " ");
        }

        public byte[] StringToByteArray(String hex)
        {
            string hex_strip = hex.Replace(" ", "");
            int NumberChars = hex_strip.Length;
            byte[] bytes = new byte[NumberChars / 2];
            for (int i = 0; i < NumberChars; i += 2)
            {
                bytes[i / 2] = Convert.ToByte(hex_strip.Substring(i, 2), 16);
            }
            return bytes;
        }
    }
}
"@;

$filename = "./sublime_text.exe"

[byte[]]$bytes = [System.IO.File]::ReadAllBytes($filename)

$sharp = New-Object -TypeName Powershell.ByteManipulation

$hex = $sharp.ByteArrayToString($bytes)

if (!$hex.Contains($find_bytes))
{
    Write-Output "Error: Pattern ($find_bytes) not found."
    Read-Host -Prompt "Press Enter to exit"
    exit
}

Write-Output "Pattern found... Patching"

$patch = $hex.replace($find_bytes, $patch_bytes)

Move-Item $filename "$filename.bak" -Force -ErrorVariable +file_backup
if ($file_backup)
{
    Write-Output "Backup unsuccessful, are you using Sublime?"
    Read-Host -Prompt "Press Enter to exit"
    exit
}

$patched_bytes = $sharp.StringToByteArray($patch)

[System.IO.File]::WriteAllBytes($filename, $patched_bytes)

Write-Host "Done!"
Read-Host -Prompt "Press Enter to exit"