import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.File;

public class ConvertImage {

    private static final String NEW_LINE = System.lineSeparator();
    private static final String UNKNOWN_CHARACTER = ".";


    public static void main(String[] args) {

        // https://mkyong.com/java/how-to-convert-file-to-hex-in-java/
        // Literally plagarized 

        final String INPUT_FILE = "I:\\Desktop\\ACADEMIC_CLASSES\\ECE554\\ECE554_minilab0\\Minilab 2\\lab2_created_files\\image.jpg";
        final String OUTPUT_FILE = "I:\\Desktop\\ACADEMIC_CLASSES\\ECE554\\ECE554_minilab0\\Minilab 2\\lab2_created_files\\created_hex.hex";


        System.out.println("Hello");
        File path = new File(INPUT_FILE);

        String result = "";
        String hex = "";
        String input = "";
        int value;

        // path to inputstream....
        try (FileInputStream inputStream = new FileInputStream(path);
            FileWriter toWrite = new FileWriter(new File(OUTPUT_FILE), false);) {

            while ((value = inputStream.read()) != -1) {

                hex += String.format("%02X ", value);

                //If the character is unable to convert, just prints a dot "."
                if (!Character.isISOControl(value)) {
                    input += (char) value;
                } else {
                    input += UNKNOWN_CHARACTER;
                }

                // After 15 bytes, reset everything for formatting purpose
                result += String.format("%-60s%n", hex, input);
                toWrite.write(String.format("%-60s%n", hex, input));
                hex = "";
                input = "";

            }

        }

        catch (IOException e) {
            System.out.println("Some error: " + e);
        }

        System.out.println("Result: " + result);
    }
}