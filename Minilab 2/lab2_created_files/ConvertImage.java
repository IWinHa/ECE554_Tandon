import java.io.FileWriter;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.io.File;
import java.awt.image.BufferedImage;
import java.awt.Image;

public class ConvertImage {


    public static void main(String[] args) {

    

        final String INPUT_FILE = "C:\\Users\\tando\\Desktop\\UWCoding\\ECE554\\ECE554_Tandon\\Minilab 2\\lab2_created_files\\image.jpg";
        final String OUTPUT_FILE = "C:\\Users\\tando\\Desktop\\UWCoding\\ECE554\\ECE554_Tandon\\Minilab 2\\lab2_created_files\\created_hex.hex";


        File path = new File(INPUT_FILE);

        try (FileWriter toWrite = new FileWriter(new File(OUTPUT_FILE), false);) {

            Image image = ImageIO.read(path);
            BufferedImage buffered = (BufferedImage) image;

            // path to inputstream....

            for (int i = 0; i < buffered.getHeight(); i++) {
                for (int j = 0; j < buffered.getWidth(); j++) {

                    int rgb = buffered.getRGB(j, i);

                    // https://stackoverflow.com/questions/2615522/java-bufferedimage-getting-red-green-and-blue-individually
                    int red = (rgb >> 16) & 0x000000FF;
                    int green = (rgb >>8 ) & 0x000000FF;
                    int blue = (rgb) & 0x000000FF;
                    int value = (i % 2 == 0) ? ((j % 2 == 0) ? green : red) :
                                                ((j % 2 == 0) ? blue : green);

                    toWrite.write(String.format("%02X\n", value));
            }

            }

        }

        catch (IOException e) {
            System.out.println("Some error: " + e);
        }
    }
}