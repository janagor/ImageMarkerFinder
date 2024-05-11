#include <stdio.h>
#include <stdlib.h>

#define IMAGE_WIDTH 320
#define IMAGE_HEIGHT 240
#define BMP_HEADER_SIZE 54

// Struktura reprezentująca piksel
typedef struct {
    unsigned char r, g, b; // Składowe koloru: czerwony, zielony, niebieski
} Pixel;

// Funkcja wczytująca obrazek z pliku BMP
void load_image(const char *filename, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    FILE *file = fopen(filename, "rb");
    if (file == NULL) {
        fprintf(stderr, "Nie można otworzyć pliku %s\n", filename);
        exit(1);
    }

    // Przeskocz nagłówek BMP
    fseek(file, BMP_HEADER_SIZE, SEEK_SET);

    // Wczytaj piksele obrazka
    for (int y = 0; y < IMAGE_HEIGHT; y++) {
        for (int x = 0; x < IMAGE_WIDTH; x++) {
            // Wczytaj kolejny piksel
            Pixel pixel;
            fread(&pixel, sizeof(Pixel), 1, file);
            // Przypisz piksel do obrazka
            image[y][x] = pixel;
        }
    }
    fclose(file);
}

// returns number of lines to jump over (number of rows -1 on which there is a black color including this)
int check_height(int x, int y, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    int height = 0;
    //dont know if should be IMAGE_HEIGTH - 1
    if (y > 0) {
        if ((image[y-1][x].r | image[y-1][x].g | image[y-1][x].b) == 0) {
            return 0;
        }
    }
    for (int yy = y+1; yy <= IMAGE_HEIGHT-1; yy++){
        if (((image[yy][x].r | image[yy][x].g | image[yy][x].b)) != 0){
            break;
        }
        ++height;
    }
    // printf("Piksel na pozycji (%d, %d): R=%d, G=%d, B=%d\n", x, y, image[y][x].r, image[y][x].g, image[y][x].b);
    // printf("Height = %d\n", height);
    return height;
}

int check_wing_length(int x, int y, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    int length = 0;
    for (int xx = x+1; xx < IMAGE_WIDTH; xx++){
        if ((image[y][xx].r | image[y][xx].g | image[y][xx].b) != 0){
            break;
        }
        ++length;
    }
    // printf("Wing length = %d\n", length);
    return length;
}
// rectangle does not involve the height line that we already checked in check_heght. Therefore it can do nothing if width is equal 0
// return 0 means no error occured, otherwise error existed and there is no marker
// (x, y) left bottom corner of rectangle
int check_rectangle(int x, int y, int width, int height, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    if (width == 0) {
        return 1;
    }
    int error = 0;
    for (int xx = x; xx < x + width; xx++) {
        for(int yy = y; yy < y + height; yy++) {
            if (((image[yy][xx].r | image[yy][xx].g | image[yy][xx].b)) != 0) {
                error = 1;
            }
        }
    }
    return error;
}

int check_remaining_rectangle_part(int x_left, int x_right, int y_down, int y_up, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    if ((x_right >=IMAGE_WIDTH) || (y_up >= IMAGE_HEIGHT)) {
        return 1;
    }
    int error = 0;
    for (int xx = x_left; xx <= x_right; xx++) {
        for(int yy = y_down; yy <= y_up; yy++) {
            if (((image[yy][xx].r | image[yy][xx].g | image[yy][xx].b)) != 0) {
                error = 1;
            }
        }
    }
    return error;
}

int check_line(int x_left, int x_right, int y_down, int y_up, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    int error = 0;
    for (int xx = x_left; xx <= x_right; xx++) {
        for(int yy = y_down; yy <= y_up; yy++) {
            if (((image[yy][xx].r | image[yy][xx].g | image[yy][xx].b)) == 0) {
                error = 1;
            }
        }
    }
    return error;
}

int process_point(int x, int y, Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    if ((x==IMAGE_WIDTH-1) || (y == IMAGE_HEIGHT-1)) {
        return 0;
    }
    // checking if height is greater than 1 and what is the value of (length - 1)
    int height_minus_one = check_height(x, y, image);
    if (height_minus_one == 0) {
        return 0;
    }
    // we need to find legth of the shorter wing. In this case 
    int wing_length_minus_one = check_wing_length(x, y, image);
    if (wing_length_minus_one >= height_minus_one) {
        return 0;
    }
    // we need to find if whole rectangle wing_length x (height + 1) is black. Height is length if vertical lien
    int error = check_rectangle(x+1, y, wing_length_minus_one, height_minus_one+1, image);
    if (error != 0) {
        return 0;
    }
    // we can say that marker are two rectangles with a common part (which is a square). We have already analysed one of rectangles. Now it is time for the other one.
    // there is no point in checking a square. Thus, we will verify only remaining part of second rectangle starting from its right upper corner (we know it has coords equal x+height and y+height)
    error = check_remaining_rectangle_part(x+wing_length_minus_one+1, x+height_minus_one, y+height_minus_one-wing_length_minus_one, y+height_minus_one, image);
    if (error != 0) {
        return 0;
    }
    // all black elements required have been checked. Now we need to check whether there are any unnecessary black pixels around. we need to go around the whole pixel and check if everything around
    // is not black
    // in order to do that we will create 3 points around that are enough, to check all the lines around: left bottom; right upper; and middle middle

    // printf("Piksel na pozycji (%d, %d): R=%d, G=%d, B=%d\n", x, y, image[y][x].r, image[y][x].g, image[y][x].b);
    //upper line
    // printf("Piksel na pozycji (%d, %d): R=%d, G=%d, B=%d\n", x, y, image[y][x].r, image[y][x].g, image[y][x].b);
    int x_down = x-1;
    int y_down = y-1;
    int x_middle = x+wing_length_minus_one+1;

    int y_middle = y+height_minus_one-wing_length_minus_one-1;
    int x_up = x+ height_minus_one+1;
    
    int y_up = y+height_minus_one+1;
    // printf("Piksel na pozycji (%d, %d): R=%d, G=%d, B=%d\n", x, y, image[y][x].r, image[y][x].g, image[y][x].b);
    // printf("%d %d %d %d %d %d\n", x_down, x_middle, x_up, y_down, y_middle, y_up);
    error = check_line(x_down, x_middle, y_down, y_down, image);
    if (error != 0) {
        return 0;
    }
    error = check_line(x_down, x_down, y_down, y_up, image);
    if (error != 0) {
        return 0;
    }
    error = check_line(x_down, x_up, y_up, y_up, image);
    if (error != 0) {
        return 0;
    }
    error = check_line(x_up, x_up, y_middle, y_up, image);
    if (error != 0) {
        return 0;
    }
    error = check_line(x_middle, x_up, y_middle, y_middle, image);
    if (error != 0) {
        return 0;
    }
    error = check_line(x_middle, x_middle, y_down, y_middle, image);
    if (error != 0) {
        return 0;
    }
    printf("Piksel na pozycji (%d, %d): R=%d, G=%d, B=%d\n", x, y, image[y][x].r, image[y][x].g, image[y][x].b);
    // printf("\n");

    // we need to find y coords of the last black pixele that is black
    // we need to find if the length of horizontal line is at least as long as height
    //check_length();
    return height_minus_one;
}

// Funkcja przetwarzająca obrazek
void process_image(Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH]) {
    // Iteracja przez piksele obrazka
    int marker_counter = 0;
    for (int x = 0; x < IMAGE_WIDTH; x++) {
        for (int y = 0; y < IMAGE_HEIGHT; y++) {
            // Przetwarzanie piksela na pozycji (x, y)
            if (((image[y][x].r | image[y][x].g | image[y][x].b)) == 0) {
                // let's assume that none zero return means that znacznik was foud. We can define, where the znacznik is just by the result
                int height = process_point(x, y, image);
                if (height > 0) {
                    y += height;
                    ++marker_counter;
                }
                // printf("Piksel na pozycji (%d, %d): R=%d, G=%d, B=%d\n", x, y, image[y][x].r, image[y][x].g, image[y][x].b);
            }
        }
    }
}

int main() {
    // Obrazek reprezentowany jako tablica pikseli
    Pixel image[IMAGE_HEIGHT][IMAGE_WIDTH];

    // Wczytaj obrazek
    load_image("example_markers.bmp", image);

    // Wywołaj funkcję przetwarzającą obrazek
    process_image(image);

    return 0;
}
