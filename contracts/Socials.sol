// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Nfts.sol";

contract SocialMedia {
    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment) public comments;
    mapping(address => uint256[]) public userPosts;
    mapping(address => uint256[]) public userComments;
    mapping(uint256 => address[]) public postLikes;
    mapping(uint256 => address[]) public postFollowers;
    uint256 public userCount;
    uint256 public postCount;
    uint256 public commentCount;
    uint256 public reportCount;

    Nfts public userNFT;

    constructor(address _userNFT) {
        userNFT = Nfts(_userNFT);
    }

    event NewPost(uint256 postId, address creator, string contentURI, uint256 timestamp);
    event NewComment(uint256 commentId, address commenter, uint256 postId, string content, uint256 timestamp);
    event LikePost(address liker, uint256 postId, uint256 timestamp);
    event FollowPost(address follower, uint256 postId, uint256 timestamp);
    event DeletePost(uint256 postId, uint256 timestamp);
    event DeleteComment(uint256 commentId, uint256 postId, uint256 timestamp);
    event Report(uint256 reportId, address reporter, string reason, uint256 timestamp);
    event ModeratePost(uint256 postId, bool approved, uint256 timestamp);
    event ModerateComment(uint256 commentId, bool approved, uint256 timestamp);

    modifier onlyUser() {
        require(users[msg.sender].isUser, "User does not exist");
        _;
    }

    modifier onlyOwner(uint256 _id) {
        require(posts[_id].creator == msg.sender || comments[_id].commenter == msg.sender, "Only owner can call this function");
        _;
    }

    modifier onlyRole(string memory _role) {
        _;
    }

    struct User {
        string username;
        uint256 age;
        bool isUser;
    }

    struct Post {
        address creator;
        string contentURI;
        uint256 timestamp;
        bool exists;
    }

    struct Comment {
        address commenter;
        string content;
        uint256 timestamp;
        bool exists;
    }

    // Define the functions for the contract
    function createUser(string memory _username, uint256 _age) external {
        require(!users[msg.sender].isUser, "User already exists");
        users[msg.sender] = User({
            username: _username,
            age: _age,
            isUser: true
        });
        userCount++;
    }

    function createPost(string memory _contentURI) external onlyUser {
        uint256 postId = postCount++;
        posts[postId] = Post({
            creator: msg.sender,
            contentURI: _contentURI,
            timestamp: block.timestamp,
            exists: true
        });
        userPosts[msg.sender].push(postId);
        emit NewPost(postId, msg.sender, _contentURI, block.timestamp);
    }

    function createComment(uint256 _postId, string memory _content) external onlyUser {
        require(posts[_postId].exists, "Post does not exist");
        uint256 commentId = commentCount++;
        comments[commentId] = Comment({
            commenter: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            exists: true
        });
        userComments[msg.sender].push(commentId);
        emit NewComment(commentId, msg.sender, _postId, _content, block.timestamp);
    }

    function likePost(uint256 _postId) external onlyUser {
        require(posts[_postId].exists, "Post does not exist");
        postLikes[_postId].push(msg.sender);
        emit LikePost(msg.sender, _postId, block.timestamp);
    }

    function followPost(uint256 _postId) external onlyUser {
        require(posts[_postId].exists, "Post does not exist");
        postFollowers[_postId].push(msg.sender);
        emit FollowPost(msg.sender, _postId, block.timestamp);
    }

    function deletePost(uint256 _postId) external onlyOwner(_postId) {
        require(posts[_postId].exists, "Post does not exist");
        delete posts[_postId];
        emit DeletePost(_postId, block.timestamp);
    }

    function deleteComment(uint256 _commentId) external onlyOwner(_commentId) {
        require(comments[_commentId].exists, "Comment does not exist");
        delete comments[_commentId];
        emit DeleteComment(_commentId, _commentId, block.timestamp);
    }

    function report(uint256 _id, string memory _reason) external onlyUser {
        require(posts[_id].exists || comments[_id].exists, "Resource does not exist");
        reportCount++;
        emit Report(reportCount, msg.sender, _reason, block.timestamp);
    }

    function moderate(uint256 _id, bool _approve) external onlyRole("moderator") {
        if (posts[_id].exists) {
            if (_approve) {
                emit ModeratePost(_id, true, block.timestamp);
            } else {
                delete posts[_id];
                emit ModeratePost(_id, false, block.timestamp);
            }
        } else {
            if (_approve) {
                emit ModerateComment(_id, true, block.timestamp);
            } else {
                delete comments[_id];
                emit ModerateComment(_id, false, block.timestamp);
            }
        }
    }
}
